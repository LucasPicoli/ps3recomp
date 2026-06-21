/* Minimal ppu_recomp.h fixture for the self-contained PPU runtime tests.
 * The real header is generated per-game by tools/ppu_lifter.py and defines an
 * identical ppu_context; the tests in this directory only need that type, so
 * the fixture defers to the canonical runtime definition. */
#ifndef PS3RECOMP_PPU_RECOMP_FIXTURE_H
#define PS3RECOMP_PPU_RECOMP_FIXTURE_H
#include "ppu_context.h"
#endif
