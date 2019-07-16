/* Start of test program */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>

size_t  write_data(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    static int first_time=1;
    char outfilename[FILENAME_MAX] = "body.out";
    static FILE *outfile;
    size_t written;
    if (first_time) {
        first_time = 0;
        outfile = fopen(outfilename,"w");
        if (outfile == NULL) {
            return -1;
        }
        fprintf(stderr,"The body is <%s>\n",outfilename);
    }
    written = fwrite(ptr,size,nmemb,outfile);
    return written;
}

int main(int argc, char **argv)
{
    CURL *curl_handle;
    char headerfilename[FILENAME_MAX] = "head.out";
    FILE *headerfile;
    int rc=0;
    curl_handle = curl_easy_init();
    curl_easy_setopt(curl_handle,   CURLOPT_URL        
,"http://curl.haxx.se");
    curl_easy_setopt(curl_handle,   CURLOPT_NOPROGRESS  ,1);
    curl_easy_setopt(curl_handle,   CURLOPT_MUTE        ,1);
    curl_easy_setopt(curl_handle,   CURLOPT_WRITEFUNCTION,&write_data);
    headerfile = fopen(headerfilename,"w");
    if (headerfile == NULL) {
        curl_easy_cleanup(curl_handle);
        return -1;
    }
    curl_easy_setopt(curl_handle,   CURLOPT_WRITEHEADER ,headerfile);
    curl_easy_perform(curl_handle);
    printf("The head is <%s>\n",headerfilename);
    fclose(headerfile);
    curl_easy_cleanup(curl_handle);
    return 0;
}
/* End of test program */

