%%%
%%% Changes name of an object in .riak_index.etf
%%%
%%% See js_handler.erl to learn what error code stands for.
%%%
-module(rename_handler).
-behavior(cowboy_handler).

-export([init/2, content_types_provided/2, content_types_accepted/2,
	 to_json/2, allowed_methods/2, forbidden/2, is_authorized/2,
	 validate_post/2, handle_post/2, rename_pseudo_directory/4]).

-include("riak.hrl").
-include("user.hrl").
-include("action_log.hrl").

init(Req, Opts) ->
    {cowboy_rest, Req, Opts}.

%%
%% Returns callback 'handle_post()'
%% ( called after 'resource_exists()' )
%%
content_types_accepted(Req, State) ->
    {[{{<<"application">>, <<"json">>, '*'}, handle_post}], Req, State}.

%%
%% Returns callback 'to_json()'
%% ( called after 'forbidden()' )
%%
content_types_provided(Req, State) ->
    {[
	{{<<"application">>, <<"json">>, []}, to_json}
    ], Req, State}.

validate_src_object_name(SrcObjectName0) ->
    case utils:ends_with(SrcObjectName0, <<"/">>) of
	true -> utils:is_valid_hex_prefix(SrcObjectName0);
	false -> true
    end.

validate_post(Req, FieldValues) ->
    Prefix = proplists:get_value(<<"prefix">>, FieldValues),
    SrcObjectName0 = proplists:get_value(<<"src_object_name">>, FieldValues),
    DstObjectName0 = proplists:get_value(<<"dst_object_name">>, FieldValues),
    case (SrcObjectName0 =:= undefined orelse DstObjectName0 =:= undefined) orelse
	    utils:is_valid_hex_prefix(Prefix) =:= false of
	true -> js_handler:bad_request(Req, 9);
	false ->
	    case validate_src_object_name(SrcObjectName0) of
		true ->
		    case utils:is_valid_object_name(DstObjectName0) of
			true ->
			    [{prefix, utils:to_lower(Prefix)},
			     {src_object_name, string:to_lower(erlang:binary_to_list(SrcObjectName0))},
			     {dst_object_name, unicode:characters_to_list(DstObjectName0)}];
			false -> js_handler:bad_request(Req, 9)
		    end;
		false -> js_handler:bad_request(Req, 9)
	    end
    end.

%%
%% Validates provided fields and updates object index, in case of object rename
%% or moves objects to the new prefix, in case prefix rename requested.
%%
handle_post(Req0, State0) ->
    BucketId = proplists:get_value(bucket_id, State0),
    case cowboy_req:method(Req0) of
	<<"POST">> ->
	    {ok, Body, Req1} = cowboy_req:read_body(Req0),
	    case jsx:is_json(Body) of
		{error, badarg} -> js_handler:bad_request(Req1, 21);
		false -> js_handler:bad_request(Req1, 21);
		true ->
		    FieldValues = jsx:decode(Body),
		    case validate_post(Req1, FieldValues) of
			{true, Req3, []} -> {true, Req3, []};  % error
			State1 -> rename(Req0, BucketId, State0 ++ State1)
		    end
	    end;
	_ -> js_handler:bad_request(Req0, 2)
    end.


copy_delete(BucketId, PrefixedSrcDirectoryName, PrefixedDstDirectoryName, PrefixedObjectName0) ->
    PrefixedObjectName1 = re:replace(PrefixedObjectName0, "^" ++ PrefixedSrcDirectoryName, "", [{return, list}]),
    %% We have cheked previously that destination directory do not exist
    PrefixedObjectName2 = utils:prefixed_object_name(PrefixedDstDirectoryName, PrefixedObjectName1),

    riak_api:copy_object(BucketId, PrefixedObjectName2, BucketId, PrefixedObjectName0, [{acl, public_read}]),

    %% Delete regular object
    riak_api:delete_object(BucketId, PrefixedObjectName0),
    PrefixedObjectName2.

%%
%% Rename can be performed within one bucket only for now.
%%
%% Prefix0 -- current pseudo-directory
%%
%% SrcDirectoryName0 -- hex encoded pseudo-directory, that should be renamed
%%
-spec rename_pseudo_directory(string(), string()|undefined, string(), string()) -> not_found|exists|true.

rename_pseudo_directory(BucketId, Prefix0, SrcDirectoryName0, DstDirectoryName0)
	when erlang:is_list(BucketId), erlang:is_list(Prefix0) orelse Prefix0 =:= undefined,
	     erlang:is_list(SrcDirectoryName0), erlang:is_list(DstDirectoryName0) ->
    PrefixedSrcDirectoryName =
	case Prefix0 of
	    undefined -> SrcDirectoryName0;
	    _ ->
		utils:prefixed_object_name(Prefix0, SrcDirectoryName0)
	end,
    PrefixedSrcIndexObjectName = utils:prefixed_object_name(PrefixedSrcDirectoryName, ?RIAK_INDEX_FILENAME),
    %% Check if pseudo-directory exists first
    case riak_api:head_object(BucketId, PrefixedSrcIndexObjectName) of
	not_found -> not_found;
	_ ->
	    %% Check if destination name exists already
	    PrefixedDstDirectoryName =
		case Prefix0 of
		    undefined ->
			utils:hex(unicode:characters_to_binary(DstDirectoryName0))++"/";
		    _ ->
			DstDirectoryName1 = utils:hex(unicode:characters_to_binary(DstDirectoryName0)),
			utils:prefixed_object_name(Prefix0, DstDirectoryName1)++"/"
		end,
	    PrefixedDstIndexObjectName = utils:prefixed_object_name(PrefixedDstDirectoryName,
		?RIAK_INDEX_FILENAME),
	    case riak_api:head_object(BucketId, PrefixedDstIndexObjectName) of
		not_found ->
		    List0 = riak_api:recursively_list_pseudo_dir(BucketId, PrefixedSrcDirectoryName),
		    [copy_delete(BucketId, PrefixedSrcDirectoryName, PrefixedDstDirectoryName,
			PrefixedObjectName) || PrefixedObjectName <- List0,
			lists:suffix(?RIAK_INDEX_FILENAME, PrefixedObjectName) =/= true],

		    [move_handler:update_pseudo_directory_index(BucketId, BucketId, PrefixedObjectName,
			copy_handler:shorten_pseudo_directory_name(PrefixedObjectName,
			    PrefixedSrcDirectoryName, PrefixedDstDirectoryName, []),
			PrefixedDstDirectoryName) || PrefixedObjectName <- List0,
		     lists:suffix(?RIAK_INDEX_FILENAME, PrefixedObjectName) =:= true],

		    %% Update source directory index
		    riak_index:update(BucketId, Prefix0),
		    true;
		_ ->
		    exists
	    end
    end.


rename(Req0, BucketId, State) ->
    Prefix0 = proplists:get_value(prefix, State),
    SrcObjectName0 = proplists:get_value(src_object_name, State),
    DstObjectName0 = proplists:get_value(dst_object_name, State),
    User = proplists:get_value(user, State),
    ActionLogRecord0 = #riak_action_log_record{
	action="rename",
	user_name=User#user.name,
	tenant_name=User#user.tenant_name,
	timestamp=io_lib:format("~p", [utils:timestamp()])
    },
    case string:sub_string(SrcObjectName0, length(SrcObjectName0), length(SrcObjectName0)) =:= "/" of
	true ->
	    case rename_pseudo_directory(BucketId, Prefix0, SrcObjectName0, DstObjectName0) of
		not_found -> js_handler:bad_request(Req0, 9);
		exists -> js_handler:bad_request(Req0, 10);
		true ->
		    %% Create action log record
		    SrcObjectName1 = unicode:characters_to_list(utils:unhex(erlang:list_to_binary(SrcObjectName0))),
		    Summary0 = lists:flatten([["Renamed \""], [SrcObjectName1], ["\" to \""], [DstObjectName0], "\""]),
		    ActionLogRecord1 = ActionLogRecord0#riak_action_log_record{details=Summary0},
		    action_log:add_record(BucketId, Prefix0, ActionLogRecord1),
		    {true, Req0, State}
	    end;
	false ->
	    PrefixedSrcObjectName = utils:prefixed_object_name(Prefix0, SrcObjectName0),
	    ObjectMetaData = riak_api:head_object(BucketId, PrefixedSrcObjectName),
	    ContentLength = proplists:get_value(content_length, ObjectMetaData),

	    %% Update objects index with new name
	    riak_index:update(BucketId, Prefix0,
		[{renamed, [{SrcObjectName0, [{name, DstObjectName0},
					      {bytes, utils:to_integer(ContentLength)}]}]}]),
	    %% Find original object name for action log record
	    Metadata = riak_api:get_object_metadata(BucketId, PrefixedSrcObjectName),
	    OrigName0 =
		case proplists:get_value("x-amz-meta-orig-filename", Metadata, SrcObjectName0) of
		    undefined -> SrcObjectName0;
		    N -> N
		end,
	    %% Create action log record
	    OrigName1 = unicode:characters_to_list(erlang:list_to_binary(OrigName0)),
	    Summary1 = lists:flatten([["Renamed \""], [OrigName1], ["\" to \""], [DstObjectName0], ["\""]]),
	    ActionLogRecord2 = ActionLogRecord0#riak_action_log_record{details=Summary1},
	    action_log:add_record(BucketId, Prefix0, ActionLogRecord2),
	    {true, Req0, []}
    end.

%%
%% Serializes response to json
%%
to_json(Req0, State) ->
    {"{\"status\": \"ok\"}", Req0, State}.

%%
%% Called first
%%
allowed_methods(Req, State) ->
    {[<<"POST">>], Req, State}.

%%
%% Checks if provided token is correct.
%% ( called after 'allowed_methods()' )
%%
is_authorized(Req0, _State) ->
    case utils:check_token(Req0) of
	undefined -> {{false, <<"Token">>}, Req0, []};
	not_found -> {{false, <<"Token">>}, Req0, []};
	expired -> {{false, <<"Token">>}, Req0, []};
	User -> {true, Req0, User}
    end.

%%
%% Checks if user has access
%% ( called after 'is_authorized()' )
%%
forbidden(Req0, State) ->
    BucketId = erlang:binary_to_list(cowboy_req:binding(bucket_id, Req0)),
    case utils:is_valid_bucket_id(BucketId, State#user.tenant_id) of
	true ->
	    UserBelongsToGroup = lists:any(fun(Group) ->
		utils:is_bucket_belongs_to_group(BucketId, State#user.tenant_id, Group#group.id) end,
		State#user.groups),
	    case UserBelongsToGroup of
		false -> {true, Req0, []};
		true -> {false, Req0, [{user, State}, {bucket_id, BucketId}]}
	    end;
	false -> {true, Req0, []}
    end.