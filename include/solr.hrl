-define(SOLR_INDEX_NAME, "binary_objects").
-define(SOLR_HOST_CONTEXT, "/internal_solr").
-define(MAXIMUM_FILE_SIZE, 20971520). % 20 MB

-define(SOLR_PORT, 8093).

-define(SOLR_MIME_TYPES, [{"dif","application/dif+xml"},
 {"vcf","text/x-vcard"},
 {"vcs","text/x-vcalendar"},
 {"uu","text/x-uuencode"},
 {"etx","text/x-setext"},
 {"java","text/x-java-source"},
 {"hh","text/x-c++hdr"},
 {"h","text/x-chdr"},
 {"cpp","text/x-c++src"},
 {"cxx","text/x-c++src"},
 {"cc","text/x-c++src"},
 {"c","text/x-csrc"},
 {"asm","text/x-assembly"},
 {"s","text/x-assembly"},
 {"wmls","text/vnd.wap.wmlscript"},
 {"wml","text/vnd.wap.wml"},
 {"ms","text/troff"},
 {"me","text/troff"},
 {"man","text/troff"},
 {"roff","text/troff"},
 {"tr","text/troff"},
 {"t","text/troff"},
 {"tsv","text/tab-separated-values"},
 {"sgm","text/sgml"},
 {"sgml","text/sgml"},
 {"rtx","text/richtext"},
 {"dsc","text/prs.lines.tag"},
 {"in","text/plain"},
 {"log","text/x-log"},
 {"list","text/plain"},
 {"def","text/plain"},
 {"conf","text/plain"},
 {"text","text/plain"},
 {"txt","text/plain"},
 {"htm","text/html"},
 {"html","text/html"},
 {"csv","text/csv"},
 {"css","text/css"},
 {"ifb","text/calendar"},
 {"ics","text/calendar"},
 {"mime","message/rfc822"},
 {"eml","message/rfc822"},
 {"xvm","application/xv+xml"},
 {"xvml","application/xv+xml"},
 {"xhvml","application/xv+xml"},
 {"mxml","application/xv+xml"},
 {"xspf","application/xspf+xml"},
 {"xslt","application/xslt+xml"},
 {"xop","application/xop+xml"},
 {"dtd","application/xml-dtd"},
 {"xsl","application/xml"},
 {"xml","application/xml"},
 {"xht","application/xhtml+xml"},
 {"xhtml","application/xhtml+xml"},
 {"crt","application/x-x509-ca-cert"},
 {"src","application/x-wais-source"},
 {"texi","application/x-texinfo"},
 {"texinfo","application/x-texinfo"},
 {"tex","application/x-tex"},
 {"sh","application/x-sh"},
 {"bat","application/x-msdownload"},
 {"com","application/x-msdownload"},
 {"mobi","application/x-mobipocket-ebook"},
 {"prc","application/x-mobipocket-ebook"},
 {"latex","application/x-latex"},
 {"csh","application/x-csh"},
 {"chat","application/x-chat"},
 {"torrent","application/x-bittorrent"},
 {"wsdl","application/wsdl+xml"},
 {"oth","application/vnd.oasis.opendocument.text-web"},
 {"ott","application/vnd.oasis.opendocument.text-template"},
 {"otm","application/vnd.oasis.opendocument.text-master"},
 {"odt","application/vnd.oasis.opendocument.text"},
 {"ots","application/vnd.oasis.opendocument.spreadsheet-template"},
 {"ods","application/vnd.oasis.opendocument.spreadsheet"},
 {"otp","application/vnd.oasis.opendocument.presentation-template"},
 {"odp","application/vnd.oasis.opendocument.presentation"},
 {"wpl","application/vnd.ms-wpl"},
 {"wdb","application/vnd.ms-works"},
 {"wcm","application/vnd.ms-works"},
 {"wks","application/vnd.ms-works"},
 {"wps","application/vnd.ms-works"},
 {"dotm","application/vnd.ms-word.template.macroenabled.12"},
 {"docm","application/vnd.ms-word.document.macroenabled.12"},
 {"mpt","application/vnd.ms-project"},
 {"mpp","application/vnd.ms-project"},
 {"potm","application/vnd.ms-powerpoint.template.macroenabled.12"},
 {"ppsm","application/vnd.ms-powerpoint.slideshow.macroenabled.12"},
 {"sldm","application/vnd.ms-powerpoint.slide.macroenabled.12"},
 {"pptm","application/vnd.ms-powerpoint.presentation.macroenabled.12"},
 {"ppam","application/vnd.ms-powerpoint.addin.macroenabled.12"},
 {"pot","application/vnd.ms-powerpoint"},
 {"pps","application/vnd.ms-powerpoint"},
 {"ppt","application/vnd.ms-powerpoint"},
 {"lrm","application/vnd.ms-lrm"},
 {"ims","application/vnd.ms-ims"},
 {"xltm","application/vnd.ms-excel.template.macroenabled.12"},
 {"xlsm","application/vnd.ms-excel.sheet.macroenabled.12"},
 {"xlsb","application/vnd.ms-excel.sheet.binary.macroenabled.12"},
 {"xlam","application/vnd.ms-excel.addin.macroenabled.12"},
 {"xlw","application/vnd.ms-excel"},
 {"xlt","application/vnd.ms-excel"},
 {"xlc","application/vnd.ms-excel"},
 {"xla","application/vnd.ms-excel"},
 {"xlm","application/vnd.ms-excel"},
 {"xls","application/vnd.ms-excel"},
 {"sbml","application/sbml+xml"},
 {"rtf","application/rtf"},
 {"rss","application/rss+xml"},
 {"rsd","application/rsd+xml"},
 {"rs","application/rls-services+xml"},
 {"rld","application/resource-lists-diff+xml"},
 {"rl","application/resource-lists+xml"},
 {"rif","application/reginfo+xml"},
 {"rdf","application/rdf+xml"},
 {"ps","application/postscript"},
 {"pls","application/pls+xml"},
 {"pdf","application/pdf"},
 {"xer","application/patch-ops-error+xml"},
 {"onepkg","application/onenote"},
 {"onetmp","application/onenote"},
 {"onetoc2","application/onenote"},
 {"onetoc","application/onenote"},
 {"opf","application/oebps-package+xml"},
 {"mathml","application/mathml+xml"},
 {"mb","application/mathematica"},
 {"nb","application/mathematica"},
 {"ma","application/mathematica"},
 {"lostxml","application/lost+xml"},
 {"emma","application/emma+xml"},
 {"ccxml","application/ccxml+xml"},
 {"atomsvc","application/atomsvc+xml"},
 {"atomcat","application/atomcat+xml"},
 {"atom","application/atom+xml"},
 {"json","application/json"},
 {"js","application/javascript"},
 {"ecma","application/ecmascript"},
 {"dot","application/msword"},
 {"doc","application/msword"},
 {"dotx",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.template"},
 {"docx",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
 {"xltx",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.template"},
 {"xlsx","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
 {"potx",
  "application/vnd.openxmlformats-officedocument.presentationml.template"},
 {"ppsx",
  "application/vnd.openxmlformats-officedocument.presentationml.slideshow"},
 {"sldx","application/vnd.openxmlformats-officedocument.presentationml.slide"},
 {"pptx",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation"},
 {"oxt","application/vnd.openofficeorg.extension"}]).
