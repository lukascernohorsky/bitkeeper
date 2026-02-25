/*
 * Copyright 2007-2008,2016 BitMover, Inc
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

#include <stdarg.h>
#include <stdio.h>

/* Define bk_fprintf as an alias for fprintf */
int
bk_fprintf(FILE *fp, const char *fmt, ...)
{
	va_list ap;
	int ret;

	if (fp == NULL) {
		return -1;
	}
	if (fmt == NULL) {
		return -1;
	}

	va_start(ap, fmt);
	ret = vfprintf(fp, fmt, ap);
	va_end(ap);
	return (ret);
}