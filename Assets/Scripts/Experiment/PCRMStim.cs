/* PCRMStim.cs
 * Stimulus images appear on the walls of the environment, as
 * paintings or artwork. This class contains methods for loading
 * images and calculating stimulus positions. Each instance
 * manages one corresponding GameObject.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using UnityEngine;
using System;
using System.IO;
using static System.Math;

public class PCRMStim : IDisposable {

    public const uint ARMS = 8;
    public const uint SIDES = 19;
    public const float STIM_Y = 2;

    protected readonly uint position;
    protected readonly GameObject gobj;
    protected readonly Renderer renderer;

    public PCRMStim(uint position, string imgpath, float scale=.15f) {
        this.position = position;

        gobj = GameObject.CreatePrimitive(PrimitiveType.Plane);
        gobj.name = $"{GetType().Name} {position} ({Path.GetFileName(imgpath)})";

        gobj.transform.localScale = new Vector3(scale, 1, scale);
        gobj.transform.eulerAngles = new Vector3(-90, get_orientation_y(), 0);
        gobj.transform.position = get_coordinates();

        renderer = gobj.GetComponent<Renderer>();

        renderer.material.shader = Shader.Find("Universal Render Pipeline/Unlit");

        renderer.material.mainTexture = ImportTexture.loadTexture(imgpath, 0);
        // renderer.material.SetFloat("_Metallic", 0f);
        // renderer.material.SetFloat("_Smoothness", .1f);
        // renderer.material.SetInteger("_Cull", (int) CullMode.Back);
    }

    public void Dispose()
    {
        UnityEngine.Object.DestroyImmediate(gobj);
    }

    // Deprecated. The default material should be URP/Unlit (self-illuminating).
    // This is inherited from the alpha version in which each painting had a spotlight on it.
    void add_spotlight()
    {
        GameObject spl_gobj = new GameObject();
        Light light = spl_gobj.AddComponent<Light>();
        light.type = LightType.Spot;
        light.range = 2.333f;
        light.intensity = 100f;
        light.shadows = LightShadows.Soft;
        light.innerSpotAngle = 0;
        light.spotAngle = 60;

        spl_gobj.transform.position = gobj.transform.position + gobj.transform.up * 2;
        spl_gobj.transform.LookAt(gobj.transform.position);
        spl_gobj.transform.parent = gobj.transform;
    }

    protected virtual Vector3 get_coordinates()
    {
        if (position > ARMS)
            throw new  ArgumentOutOfRangeException("position", $"Position of {position} exceeds the number of arms (8).");

        // if (position == 0)
        //     return new Vector3(0, STIM_Y, 0);

        return new Vector3(
            (float)Sin(4 * PI * position / 18) / 2 * 15,
            STIM_Y,
            (float)Cos(4 * PI * position / 18) / 2 * 15
        );
    }

    protected virtual float get_orientation_y()
    {
        return 40 * position;
    }
};


public class PCRMStimOuter : PCRMStim {
    public PCRMStimOuter(uint position, string imgpath, float scale = 0.15F) : base(position, imgpath, scale) {}
    

    // The calculation of coordinates and orientation will be different for the outer/arm-end stimuli.
    protected override Vector3 get_coordinates()
    {
        if (position > ARMS)
            throw new  ArgumentOutOfRangeException(nameof(position), $"Position of {position} exceeds the number of arms (8).");

        return new Vector3(
            (float)Sin(4 * PI * position / 18) / 2 * 15 * 5.5f + (float)(Cos(4 * PI * position / 18) * 1.45 * Sin(PI / 18) * 15),
            STIM_Y,
            (float)Cos(4 * PI * position / 18) / 2 * 15 * 5.5f - (float)(Sin(4 * PI * position / 18) * 1.45 * Sin(PI / 18) * 15)
        );
    }

    protected override float get_orientation_y()
    {
        return 40 * position + 90;
    }
};



