pub usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_opengl.h");
    @cInclude("nanovg.h");
    @cDefine("NANOVG_GL2", "1");
    @cInclude("nanovg_gl.h");
});
