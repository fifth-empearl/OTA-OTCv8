#include "truetypefont.h"
#include "texture.h"
#include "image.h"

#include <framework/core/resourcemanager.h>
#include <framework/core/logger.h>

#include <ft2build.h>
#include FT_FREETYPE_H

bool TrueTypeFont::loadTtf(const std::string& file, int size)
{
    std::string path = g_resources.guessFilePath(file, "ttf");
    m_source = path;
    m_size = size;
    std::string data;
    try {
        data = g_resources.readFileContents(path);
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("Unable to read font '%s': %s", file, e.what()));
        return false;
    }

    FT_Library library;
    if (FT_Init_FreeType(&library)) {
        g_logger.error("Unable to init FreeType library");
        return false;
    }

    FT_Face face;
    if (FT_New_Memory_Face(library, reinterpret_cast<const FT_Byte*>(data.c_str()), data.size(), 0, &face)) {
        g_logger.error(stdext::format("Unable to load ttf font '%s'", file));
        FT_Done_FreeType(library);
        return false;
    }

    FT_Set_Pixel_Sizes(face, 0, size);
    m_firstGlyph = 32;
    m_glyphHeight = size;
    m_yOffset = 0;
    m_underlineOffset = 0;
    m_glyphSpacing = Size(0, 0);

    const int maxWidth = 512;
    int x = 0, y = 0, rowHeight = 0;
    int atlasWidth = 0, atlasHeight = 0;

    for (int ch = m_firstGlyph; ch < 256; ++ch) {
        if (FT_Load_Char(face, ch, FT_LOAD_RENDER))
            continue;
        FT_GlyphSlot g = face->glyph;
        if (x + g->bitmap.width + 1 >= maxWidth) {
            atlasWidth = std::max(atlasWidth, x);
            atlasHeight += rowHeight + 1;
            x = 0;
            rowHeight = 0;
        }
        x += g->bitmap.width + 1;
        rowHeight = std::max(rowHeight, (int)g->bitmap.rows);
    }
    atlasWidth = std::max(atlasWidth, x);
    atlasHeight += rowHeight;

    ImagePtr image = std::make_shared<Image>(Size(std::max(atlasWidth,1), std::max(atlasHeight,1)));
    // clear image
    for (int iy = 0; iy < atlasHeight; ++iy) {
        for (int ix = 0; ix < atlasWidth; ++ix) {
            image->setPixel(ix, iy, Color(255, 255, 255, 0));
        }
    }

    x = y = rowHeight = 0;
    for (int ch = m_firstGlyph; ch < 256; ++ch) {
        if (FT_Load_Char(face, ch, FT_LOAD_RENDER))
            continue;
        FT_GlyphSlot g = face->glyph;
        if (x + g->bitmap.width + 1 >= maxWidth) {
            x = 0;
            y += rowHeight + 1;
            rowHeight = 0;
        }

        FT_Bitmap& bmp = g->bitmap;
        for (int iy = 0; iy < (int)bmp.rows; ++iy) {
            for (int ix = 0; ix < (int)bmp.width; ++ix) {
                unsigned char val = bmp.buffer[iy * bmp.pitch + ix];
                if (val) {
                    image->setPixel(x + ix, y + iy, Color(255, 255, 255, val));
                }
            }
        }

        m_glyphsTextureCoords[ch].setRect(x, y, bmp.width, bmp.rows);
        m_glyphsSize[ch].resize(bmp.width, bmp.rows);

        x += bmp.width + 1;
        rowHeight = std::max(rowHeight, (int)bmp.rows);
    }

    m_texture = std::make_shared<Texture>(image);
    m_texture->setSmooth(true);

    FT_Done_Face(face);
    FT_Done_FreeType(library);
    return true;
}
