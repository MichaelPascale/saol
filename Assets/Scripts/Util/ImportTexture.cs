// using System.Collections.Generic;
// using System.IO;
// using UnityEngine;
// using SixLabors.ImageSharp;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using UnityEngine;
public class ImportTexture
{
    static public Texture2D loadTexture(string path, float blur=0)
    {


        var m = Image.Load<Rgba32>(path);

        if (blur > 0)
            m.Mutate(ctx => ctx.GaussianBlur(blur));

        Texture2D t = new Texture2D(m.Width, m.Height, TextureFormat.RGBA32, false);
        var pixelData = new byte[m.Width * m.Height * 4];

        ImageFrame f = m.Frames.RootFrame;

        m.CopyPixelDataTo(pixelData);
        t.LoadRawTextureData(pixelData);
        t.Apply();

        return t;

    }
}

