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



