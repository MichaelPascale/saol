using System;
using static System.Math;
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;
using System.IO;

public class Trial : MonoBehaviour
{

    public int duration_s = 30;
    public PlayerController controller;

    public GameObject UICanvas;
    public Text UITextBox;

    private uint trial;
    private DateTime t_init;
    private DateTime t_trial_onset;

    private System.Random random = new();

    private List<string> stimuli;
    private TableWriter<Tuple<string, float>> data_trial_order;
    void Start()
    {
        t_init = DateTime.Now;
        t_trial_onset = t_init;
        trial = 1;
        Debug.Log("Began experiment at: " + t_init);


        List<GameObject> clearPaintings = new();
        List<GameObject> blurPaintings = new();

        stimuli = new(Directory.GetFiles("Assets/Textures/SVLO", "*.png"));

        List<Tuple<string, float>> pairs = random_sample();
        data_trial_order = new(new string[2] { "image", "sigma" }, tuple => $"{tuple.Item1}\t{tuple.Item2}");
        data_trial_order.append(pairs);
        data_trial_order.write("pairs.tsv");

        for (int i = 1; i <= 8; i++)
        {
            GameObject p = GameObject.CreatePrimitive(PrimitiveType.Plane);
            p.transform.localScale = new Vector3(.15f, 1, .15f);
            p.transform.eulerAngles = new Vector3(-90, 40 * i, 0); // Rotate to face center
            p.transform.position = new Vector3(
                (float)Sin(4 * PI * i / 18) / 2 * 15,
                2,
                (float)Cos(4 * PI * i / 18) / 2 * 15
            );

            p.GetComponent<Renderer>().material.mainTexture = ImportTexture.loadTexture(pairs[i - 1].Item1, pairs[i - 1].Item2);
            p.GetComponent<Renderer>().material.SetFloat("_Metallic", 0f);
            p.GetComponent<Renderer>().material.SetFloat("_Smoothness", .1f);

            // No collider.
            Destroy(p.GetComponent<Collider>());

            GameObject l = new GameObject();
            Light li = l.AddComponent<Light>();
            li.type = LightType.Spot;
            li.range = 3f;
            li.intensity = 15f;
            li.shadows = LightShadows.Soft;
            li.innerSpotAngle = 40; // 50
            li.spotAngle = 60; // 90

            l.transform.position = p.transform.position + p.transform.up * 2;
            l.transform.LookAt(p.transform.position);
            l.transform.parent = p.transform;

            blurPaintings.Add(p);

            // Clarified paintings. On the far 
            p = GameObject.CreatePrimitive(PrimitiveType.Plane);
            p.transform.localScale = new Vector3(.15f, 1, .15f);
            p.transform.eulerAngles = new Vector3(-90, 40 * i + 90, 0); // Rotate to face left wall of arm
            p.transform.position = new Vector3(
                // offset   x/z ratio      *  3/2 width of hall
                (float)Sin(4 * PI * i / 18) / 2 * 15 * 5.5f + (float)(Cos(4 * PI * i / 18) * 1.45 * Sin(PI / 18) * 15),
                1.5f,
                (float)Cos(4 * PI * i / 18) / 2 * 15 * 5.5f - (float)(Sin(4 * PI * i / 18) * 1.45 * Sin(PI / 18) * 15)
            );

            p.GetComponent<Renderer>().material.mainTexture = ImportTexture.loadTexture(pairs[i - 1].Item1, 0);
            p.GetComponent<Renderer>().material.SetFloat("_Metallic", 0f);
            p.GetComponent<Renderer>().material.SetFloat("_Smoothness", .1f);


            l = new GameObject();
            li = l.AddComponent<Light>();
            li.type = LightType.Spot;
            li.range = 3f;
            li.intensity = 15f;
            li.shadows = LightShadows.Soft;
            li.innerSpotAngle = 60; // 50
            li.spotAngle = 80; // 90

            l.transform.position = p.transform.position + p.transform.up * 2;
            l.transform.LookAt(p.transform.position);
            l.transform.parent = p.transform;

            clearPaintings.Add(p);
        }

        UICanvas.SetActive(true);
        UITextBox.text = "This is a new exhibit.\nYou may spend 30s here.";
        controller.isPaused = true;
    }

    // Update is called once per frame
    void Update()
    {
        DateTime t_now = DateTime.Now;

        double elapsed_trial_s = t_now.Subtract(t_trial_onset).TotalSeconds;
        if (elapsed_trial_s >= duration_s)
        {
            t_trial_onset = t_now;
            trial++;
            Debug.Log("Trial " + trial + " complete at: " + t_now + ". (" + t_now.Subtract(t_init).TotalMilliseconds + "ms elapsed)");

            UITextBox.color = Color.green;
            UITextBox.text = "This is the next new exhibit.\nYou may spend 30s here.";
            UICanvas.SetActive(true);

            controller.isPaused = true;

            transform.position = new Vector3(0, 0, 0);
            transform.eulerAngles = new Vector3(0, 0, 0);

            return;
        }

        // TODO: Reorder all of these for efficient use of the frame.
        if ((duration_s - elapsed_trial_s) < 2)
        {
            UITextBox.text = "Time's up!";
            UITextBox.color = Color.red;
            UICanvas.SetActive(true);
            return;
        }

        if (elapsed_trial_s > 5)
            UICanvas.SetActive(false);

        if (elapsed_trial_s <= (18 + 5))
        {
            int i = (int)Floor(elapsed_trial_s - 5);
            // Every-other second, rotate to the next arm.
            if (i % 2 == 0 && i >= 0)
                transform.eulerAngles = new Vector3(0, i / 2 * 40 + (((float)(elapsed_trial_s - 5) - i) * 40), 0);
        }
        else
        {
            controller.isPaused = false;
        }


    }

    List<Tuple<string, float>> random_sample()
    {
        List<Tuple<string, float>> ret = new();
        int[] k = { 0, 1, 2, 3, 4, 5, 6, 7 };

        for (int s = 1; s <= 8; s++)
        {
            float blur = 10f * (float)Pow(40f / 10f, k[s-1] / 7f);
            Debug.Log("blur: " + blur);

            int i = random.Next(stimuli.Count);
            string stim = stimuli[i];
            stimuli.RemoveAt(i);

            ret.Add(new Tuple<string, float>(stim, blur));
        }

        return ret;
    }

}
