#pragma once

#ifndef __DBGASSERT_H__

#include <cassert>
#define ASSERTMSG(cond, msg) {\
	if (!(cond)) { \
		printf("Assertion %s failed at %s:%s:%d\n", #cond, __FILE__,  __FUNCTION__, __LINE__);\
		abort();\
	}\
}

#define ASSERT(cond) {\
	if (!(cond)) { \
		printf("Assertion %s failed at %s:%s:%d\n", #cond, __FILE__,  __FUNCTION__, __LINE__);\
		abort();\
	}\
}

#else 

#define ASSERTMSG(cond, std::string msg)
#define ASSERT(cond)

#endif


