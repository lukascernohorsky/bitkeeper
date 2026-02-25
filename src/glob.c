/*
 * Copyright 2008,2015-2016 BitMover, Inc
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

#include "sccs.h"
#include "system.h"

int
glob_main(int ac __attribute__((unused)), char **av)
{
	char	*glob = av[1];
	int	i, matched = 0;

	unless (av[1] && av[2]) usage();
	for (i = 2; av[i]; i++) {
		if (match_one((u8 *)av[i], (u8 *)glob, 0)) {
			printf("%s matches.\n", av[i]);
			matched = 1;
		}
	}
	unless (matched) {
		printf("No match.\n");
		return (1);
	}
	return (0);
}
