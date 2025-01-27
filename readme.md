***copyright (c) 2019, NESA Lab***
# 涂鸦
## espconn 
提供连接方法，对lwip的封装
## espressif 
一些公用的函数
## FreeRTOS
有13个CVE，但都是AWS上的FreeRTOS，应该是配置问题，不清楚ESP8266是否有类似问题
+ CVE-2018-16603 information leak
+ CVE-2018-16522 remote code execution
+ CVE-2018-16523 denial of service 
......
## cJSON
涂鸦用的cJSON没有注明年份，只能确定在v1.5.0之前。Github上的cJSONv1.0.0从2016年开始，未找到在此之前的cJSON的资料。
#### 1 out-of-bounds access
+ CVE-2019-11835
+ CVE-2019-11834

如果*json为空，可能导致越界访问。v1.7.11被修复
```c
CJSON_PUBLIC(void) cJSON_Minify(char *json)
```
#### 2 memory leak
+ CVE-2018-1000215

if hooks->reallocate failed and set 'buffer->buffer' to NULL without free。v1.7.7修复
```c
static unsigned char *print(const cJSON * const item, cJSON_bool format, const internal_hooks * const hooks)
```
#### 3 Use After Free
+ CVE-2018-1000217

add_item_to_object()会先deallocate再copy，导致拷贝的内存会有garbage。v1.7.4被修复
```c
static cJSON_bool add_item_to_object(cJSON * const object, const char * const string, cJSON * const item, const internal_hooks * const hooks, const cJSON_bool constant_key)
```
#### 4 Double Free
+ CVE-2018-1000216

如果item->valuestring是NULL，在未成功输出buffer时也会deallocate。v1.7.3修复
```c
static cJSON_bool print_value(const cJSON * const item, printbuffer * const output_buffer)
```

#### 5 buffer overflow / heap corruption
+ CVE-2016-4303

parse_string处理TF8/16字符串不当，可能导致heap-based buffer overflow。CVE上描述都为一个用了cJSON的iperf库，根据commit的记录和时间，现Github上的cJSON应该已经修复了（从v1.0.0开始）

#### 6 buffer overflow
+ CVE-2016-10749

如果输入字符以反斜杠结束，可能导致越界。v1.0.0已经修复
```c
static const char *parse_string(cJSON *item,const char *str,const char **ep)
```

## lwip
#### 1 cache poisoning
+ CVE-2014-4883

does not use random values for ID fields and source ports of DNS query packets。v1.4.1及之前版本存在，根据commit时间v2.0.0已经修复，之间版本没有记录。
修改了dns.c中多处代码。涂鸦sdk中看不到.c文件，也不确定涂鸦所使用版本。[代码具体修改](http://git.savannah.gnu.org/cgit/lwip.git/commit/?id=9fb46e120655ac481b2af8f865d5ae56c39b831a)

## mbedtls
#### 1 Incorrectly Signed Certificates
+ CVE-2018-1000520

当选择TLS-ECDH-RSA加密时，应该只有RSA签名可以被接受，但ECDSA签名也可以被接受。v2.7.0中存在，且似乎并没有被修复，因为开发者不认为是一个可被攻击的漏洞。[具体情况](https://github.com/ARMmbed/mbedtls/issues/1561)
```c
uint32_t mbedtls_ssl_get_verify_result( const mbedtls_ssl_context *ssl )
```

## mqtt
涂鸦使用的是IBM的mqtt，没有找到版本号。CVE上mtqq与IBM相关的是IBM cloud服务，不清楚是不是涂鸦使用的。
#### 1 dos
+ CVE-2018-1684
+ CVE-2014-0923
+ CVE-2014-0922

## nopoll
无CVE，GitHub的issue也没有提到漏洞。

## ssl
有两个目录，ssl和openssl。ssl目录下有注明axTLSv1.5.3,openssl目录下的copyright为espressif。但两个目录下的文件结构都与GitHub上的axTLS相似但不相同，怀疑是修改过的。

#### 1 buffer overflow
+ CVE-2019-8981

当ssl->need_bytes大小超过限制后，并不会被重置，使得之后的操作可能会溢出。v2.1.5被修复。
tls1.c
```c
int basic_read(SSL *ssl, uint8_t **in_data) 
```

#### 2 uncorrect signature verification
+ CVE-2018-16253
+ CVE-2018-16150
+ CVE-2018-16149

signature verification does not properly verify the ASN.1 metadata。v2.1.3存在。
x509.c
```c
static bigint *sig_verify(BI_CTX *ctx, const uint8_t *sig, int sig_len,bigint *modulus, bigint *pub_exp)
```

#### 3 coding error
+ CVE-2017-1000416

asn在处理UTC时间时，会把小于96的年份认为在21世纪，相当于1995年会被当成2095年。v1.4.3和v1.5.3存在。
asn1.c
```c
static int asn1_get_utc_time(const uint8_t *buf, int *offset, time_t *t)
```

# Linux
## libcurl
#### 1 buffer overflow
+ CVE-2019-5436

当用户指定的大小小于默认时，函数仍会使用默认大小，从而导致重写堆内存。7.19.4 to and including 7.64.1
tftp.c
```c
static CURLcode tftp_connect(struct connectdata *conn, bool *done)
```

#### 2 Integer overflows
+ CVE-2019-5435

curl_url_set接收超过8000000字节的字符串的时候会导致溢出。7.62.0 to and including 7.64.1。
urlapi.c
```c
CURLUcode curl_url_set(CURLU *u, CURLUPart what,const char *part, unsigned int flags)
```

#### 3 out-of-bounds read
+  CVE-2019-3823

If the buffer passed to smtp_endofresp() isn't NUL terminated and contains no character ending the parsed number, and len is set to 5, then the strtol() call reads beyond the allocated buffer. 7.34.0 to and including 7.63.0。

smtp.c
```c
static bool smtp_endofresp(struct connectdata *conn, char *line, size_t len,int *resp)
```

#### 4 buffer overflow
+ CVE-2019-3822

The check that exists to prevent the local buffer from getting overflowed is implemented wrongly (using unsigned math). 7.36.0 to and including 7.63.0
ntlm.c
```c
CURLcode Curl_auth_create_ntlm_type3_message(struct Curl_easy *data,const char *userp,const char *passwdp,struct ntlmdata *ntlm,char **outptr, size_t *outlen)
```

#### 5 out-of-bounds read
+ CVE-2018-16890

The function does not validate incoming data correctly and is subject to an integer overflow vulnerability.a bad length + offset combination would lead to a buffer read out-of-bounds.7.36.0 to and including 7.63.0

ntlm.c
```c
static CURLcode ntlm_decode_type2_target(struct Curl_easy *data,unsigned char *buffer,size_t size,struct ntlmdata *ntlm)
```

#### 6 Insufficiently Protected Credentials
+ CVE-2018-1000007

A remote user may be able to obtain potentially sensitive authentication information from applications that use custom 'Authorization:' headers. 6.0 to and including 7.57.0
无法确定漏洞位置。


#### 7 out-of-bounds read
+ CVE-2018-1000005

原本的格式是":"，后来改成了": "，但对应的数字下标没改。7.49.0 to and including 7.57.0.
http2.c
```c
static int on_header(nghttp2_session *session, const nghttp2_frame *frame,const uint8_t *name, size_t namelen,const uint8_t *value, size_t valuelen,uint8_t flags, void *userp)
```

#### 8 out of buffer access
+ CVE-2017-8818

The math used to calculate the extra memory amount necessary for the SSL library was wrong on 32 bit systems, which made the allocated memory too small by 4 bytes.7.56.0 to and including 7.56.1
url.c
```c
static struct connectdata *allocate_conn(struct Curl_easy *data)
```

#### 9 out of bounds read
+ CVE-2017-8817

 The built-in wildcard function has a flaw that makes it not detect the end of the pattern string if it ends with an open bracket ([) but instead it will continue reading the heap beyond the end of the URL buffer that holds the wildcard. 7.21.0 to and including 7.56.1
curl_fnmatch.c
```c
static int setcharset(unsigned char **p, unsigned char *charset)
```

#### 10 buffer overflow via integer overflow
+ CVE-2017-8816

当用户名加密码的储存空间大于2GB时，在32位系统会导致整型溢出。7.36.0 to and including 7.56.1
curl_ntlm_core.c
```c
CURLcode Curl_ntlm_core_mk_ntlmv2_hash(const char *user, size_t userlen, const char *domain, size_t domlen, unsigned char *ntlmhash, unsigned char *ntlmv2hash)
```

#### 11 TLS session resumption client cert bypass
+ CVE-2017-7468
+ CVE-2016-5419 

libcurl would attempt to resume a TLS session even if the client certificate had changed.libcurl supports by default the use of TLS session id/ticket to resume previous TLS sessions to speed up subsequent TLS handshakes.7.1 to and including 7.50.0。7.52.0 to and including 7.53.1
无法确定漏洞位置。

#### 12 out of bounds read
+ CVE-2017-1000257

如果返回的消息是0字节，libcurl会把指向不存在数据的指针和0的大小传到接收函数。接收函数会用strlen来处理，然后可能出错。 7.20.0 to and including 7.56.0
imap.c
```c
static CURLcode imap_state_fetch_resp(struct connectdata *conn,int imapcode,imapstate instate)
```

#### 13 out of bounds read
+ CVE-2017-1000254

如果路径不是用双引号闭合的，libcurl可能不会在末尾加上NUL字节，从而导致越界。7.7 to and including 7.55.1
ftp.c
```c
static CURLcode ftp_statemach_act(struct connectdata *conn)
```

#### 14 Buffer Over-read
+ CVE-2017-1000100

When doing a TFTP transfer and curl/libcurl is given a URL that contains a very long file name (longer than about 515 bytes), the file name is truncated to fit within the buffer boundaries, but the buffer size is still wrongly updated to use the untruncated length. 7.15.0 to and including 7.54.1
tftp.c
```c
static void tftp_send_first(tftp_state_data_t *state, tftp_event_t event)
```

#### 15 out of bounds read
+ CVE-2017-1000099

When asking to get a file from a file:// URL, libcurl provides a feature that outputs meta-data about the file using HTTP-like headers.The code doing this would send the wrong buffer to the user. 7.54.1
file.c
```c
static CURLcode file_do(struct connectdata *conn, bool *done)
```

#### 16 uninitialized random
+ CVE-2016-9594

libcurl's (new) internal function that returns a good 32bit random value was implemented poorly and overwrote the pointer instead of writing the value into the buffer the pointer pointed to. 7.52.0
rand.c
```c
static CURLcode randit(struct Curl_easy *data, unsigned int *rnd)
```

#### 17 buffer overflow
+ CVE-2016-9586

libcurl's implementation of the printf() functions triggers a buffer overflow when doing a large floating point output. 7.1 to and including 7.51.0
mprintf.c
```c
static int dprintf_formatf(void *data, int (*stream)(int, FILE *),const char *format,va_list ap_save) 
```

#### 18 heap overflow
+ CVE-2016-8622

当分配的buffer超过2GB时，返回的长度会是一个32的有符号数。7.24.0 to and including 7.50.3
escape.c
```c
char *curl_easy_unescape(CURL *handle, const char *string, int length, int *olen)
```

#### 19 double-free
+ CVE-2016-8618

The libcurl API function called curl_maprintf() can be tricked into doing a double-free due to an unsafe size_t multiplication, on systems using 32 bit size_t variables. 7.1 to and including 7.50.3
mprintf.c
```c
static int alloc_addbyter(int output, FILE *data)
```

#### 20 integer overflows
+ CVE-2016-7167

The provided string length arguments were not properly checked and due to arithmetic in the functions, passing in the length 0xffffffff (2^32-1 or UINT_MAX or even just -1) would end up causing an allocation of zero bytes of heap memory that curl would attempt to write gigabytes of data into. 7.11.1 to and including 7.50.2
escape.c
```c
char *curl_easy_unescape(struct Curl_easy *data, const char *string,int length, int *olen)
char *curl_easy_escape(struct Curl_easy *data, const char *string, int inlength)
```










