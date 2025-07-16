#ifndef TRUETYPEFONT_H
#define TRUETYPEFONT_H

#include "bitmapfont.h"

class TrueTypeFont : public BitmapFont
{
public:
    TrueTypeFont(const std::string& name) : BitmapFont(name) {}

    bool loadTtf(const std::string& file, int size);

    const std::string& getSource() const { return m_source; }
    int getSize() const { return m_size; }

private:
    std::string m_source;
    int m_size{0};
};

#endif
