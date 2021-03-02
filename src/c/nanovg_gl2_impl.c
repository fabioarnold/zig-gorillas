#if defined(_WIN32) || defined(__linux__)
	#include "glad/glad.h"
	#include "../src/glad.c"
#else
	#define GL_GLEXT_PROTOTYPES
#endif
#include <SDL2/SDL_opengl.h>
#include "nanovg.h"
#define NANOVG_GL2_IMPLEMENTATION
#include "nanovg_gl.h"
#include "nanovg.c"
