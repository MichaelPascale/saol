/* Overlay.cs
 * Class to handle full-screen 2D stimulus presentation.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * MIT Licensed.
 */

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SAOLOverlay : MonoBehaviour
{
    public Camera cam;
    protected Canvas canvas;
    protected Image bg;
    protected List<GameObject> fg_elements = new List<GameObject>();
    
    void Start()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        var obj = new GameObject("Background Image");
        obj.transform.SetParent(transform);
        bg = obj.AddComponent<Image>();
        bg.color = new Color(0,0,0,.75f);

        RectTransform rect = obj.GetComponent<RectTransform>();
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
        rect.sizeDelta = Vector2.zero;

        hide();
    }

    public void show()
    {
        gameObject.SetActive(true);
    }

    public void hide()
    {
        gameObject.SetActive(false);
    }
    public void text(string message, Color color = default)
    {
        if (color == default)
            color = Color.white; // Using default because function signature must be compile-time constant.

        var obj = new GameObject("Text Display");
        obj.transform.SetParent(transform);
        Text text = obj.AddComponent<Text>();
        text.text = message;
        text.color = color;
        text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        text.alignment = TextAnchor.MiddleCenter;
        text.fontSize = 32;

        RectTransform rect = obj.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.25f, 0.25f);
        rect.anchorMax = new Vector2(0.75f, 0.75f);
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;

        fg_elements.Add(obj);
    }

    public void clear()
    {
        foreach (GameObject obj in fg_elements)
            Destroy(obj);
        fg_elements.Clear();
    }

}
