/*
 * Copyright 2004,2010,2014-2016 BitMover, Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include "system.h"
#include "sccs.h"

int
regex_main(int ac, char **av)
{
        pcre2_code      *re;
        pcre2_match_data *match_data;
        int             i, errcode;
        PCRE2_SIZE      off;
        char            errbuffer[256];
        int             matched = 0;

        unless (av[1] && av[2]) usage();
        re = pcre2_compile_8((PCRE2_SPTR)av[1], PCRE2_ZERO_TERMINATED, 0, &errcode, &off, 0);
        unless (re) {
                pcre2_get_error_message_8(errcode, (PCRE2_UCHAR *)errbuffer, sizeof(errbuffer));
                fprintf(stderr, "pcre2_compile returned error: %s\n", errbuffer);
                return(1);
        }
        match_data = pcre2_match_data_create_from_pattern_8(re, 0);
        for (i = 2; av[i]; i++) {
                if (pcre2_match_8(re, (PCRE2_SPTR)av[i], strlen(av[i]), 0, 0, match_data, 0) >= 0) {
                        printf("%s matches.\n", av[i]);
                        matched = 1;
                }
        }
        unless (matched) printf("No match.\n");
        pcre2_match_data_free_8(match_data);
        pcre2_code_free_8(re);
        return (matched ? 0 : 1);
}
