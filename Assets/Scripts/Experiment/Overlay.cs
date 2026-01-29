/* Overlay.cs
 * Class to handle full-screen 2D stimulus presentation.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * MIT Licensed.
 */

using System.Collections.Generic;
using Unity.Collections;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class SAOLOverlay : MonoBehaviour
{
    public bool isVisible = false;
    public Camera cam;
    protected Canvas canvas;
    protected Image bg_image;
    protected List<Text> fg_elements;
    
    void Start()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        bg_image = canvas.AddComponent<Image>();
        bg_image.color = new Color(0,0,0,211);

        text("5", 0.2f, 0.2f);
    }

    void show()
    {
        gameObject.SetActive(true);
        isVisible = true;
    }

    void hide()
    {
        gameObject.SetActive(false);
    }
    void text(string message, float x = .5f, float y = .5f, Color color = default)
    {
        if (color == default)
            color = Color.white; // Using default because function signature must be compile-time constant.

        Text text = gameObject.AddComponent<Text>();
        text.text = message;
        text.color = color;
        text.rectTransform.pivot = new Vector2(x,y);
        fg_elements.Add(text);
    }

    void clear()
    {
        foreach (Text text in fg_elements)
            Destroy(text);
        fg_elements.Clear();
    }

}
