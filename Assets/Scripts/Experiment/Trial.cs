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
    public GameObject player;

    public GameObject UICanvas;
    public Text UITextBox;

    private uint trial;
    private DateTime t_init;
    private DateTime t_trial_onset;

    private System.Random random = new();

    private List<string> stimuli;
    private TableWriter<(uint, string, float)> data_trial_order;
    public TableWriter<(uint, double, float, float, float)> data_behavior;

    private List<GameObject> clearPaintings = new();
    private List<GameObject> blurPaintings = new();
    void Start()
    {
        t_init = DateTime.Now;
        t_trial_onset = t_init;
        trial = 0;
        Debug.Log("Began experiment at: " + t_init);


        List<GameObject> clearPaintings = new();
        List<GameObject> blurPaintings = new();

        stimuli = new(Directory.GetFiles("Assets/Textures/SVLO", "*.png"));

        data_trial_order = new(new string[] { "trial", "image", "sigma" }, tuple => $"{tuple.Item1}\t{tuple.Item2}\t{tuple.Item3}");
        data_behavior = new(new string[] { "trial", "time", "x", "z", "roty" }, tuple => $"{tuple.Item1}\t{tuple.Item2}\t{tuple.Item3}\t{tuple.Item4}\t{tuple.Item5}");

        next();
    }

    // Update is called once per frame
    void Update()
    {
        DateTime t_now = DateTime.Now;

        if (trial == 11)
            return;

        double elapsed_trial_s = t_now.Subtract(t_trial_onset).TotalSeconds;
        data_behavior.append((trial, elapsed_trial_s, player.transform.position.x, player.transform.position.z, player.transform.rotation.y));

        if (elapsed_trial_s >= duration_s)
        {
            t_trial_onset = t_now;
            Debug.Log("Trial " + trial + " complete at: " + t_now + ". (" + t_now.Subtract(t_init).TotalMilliseconds + "ms elapsed)");
            next();
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

    List<(uint, string, float)> random_sample()
    {
        List<(uint, string, float)> ret = new();
        List<int> k = new List<int> { 0, 1, 2, 3, 4, 5, 6, 7 };

        for (int s = 1; s <= 8; s++)
        {
            int i = random.Next(stimuli.Count);
            string stim = stimuli[i];
            stimuli.RemoveAt(i);

            i = random.Next(k.Count);
            float blur = 10f * (float)Pow(40f / 10f, k[i] / 7f);
            Debug.Log("blur: " + blur);
            k.RemoveAt(i);

            ret.Add((trial, stim, blur));
        }

        return ret;
    }
    GameObject painting(float x, float z, float theta, string imgpath, float blur = 0, float scale = .15f, float y = 2)
    {
        GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Plane);
        obj.transform.localScale = new Vector3(scale, 1, scale);
        obj.transform.eulerAngles = new Vector3(-90, theta, 0);
        obj.transform.position = new Vector3(x, y, z);
        obj.GetComponent<Renderer>().material.mainTexture = ImportTexture.loadTexture(imgpath, blur);
        obj.GetComponent<Renderer>().material.SetFloat("_Metallic", 0f);
        obj.GetComponent<Renderer>().material.SetFloat("_Smoothness", .1f);

        return obj;
    }

    GameObject spotlight(GameObject on)
    {
        GameObject obj = new GameObject();
        Light light = obj.AddComponent<Light>();
        light.type = LightType.Spot;
        light.range = 2.333f;
        light.intensity = 100f;
        light.shadows = LightShadows.Soft;
        light.innerSpotAngle = 0;
        light.spotAngle = 60;

        obj.transform.position = on.transform.position + on.transform.up * 2;
        obj.transform.LookAt(on.transform.position);
        obj.transform.parent = on.transform;

        return obj;
    }

    // Begin the next trial.
    void next()
    {
        if (trial == 10)
            end();
        
        trial++;
        List<(uint, string, float)> trial_params = random_sample();
        data_trial_order.append(trial_params);

        UITextBox.color = Color.green;
        UITextBox.text = "This is the next floor of the museum. You will have thirty seconds to spend here.";
        UICanvas.SetActive(true);
        controller.isPaused = true;

        transform.position = new Vector3(0, 1.08f, 0);
        transform.eulerAngles = new Vector3(0, 0, 0);

        build_stim(trial_params);
    }

    void end()
    {
        string timestamp = t_init.ToUniversalTime().ToString("yyyyMMdd'T'HHmmss'Z'");
        data_trial_order.write("TrialData_" + timestamp + ".tsv");
        data_behavior.write("PoseData_" + timestamp + ".tsv");


        UITextBox.color = Color.white;
        UITextBox.text = "Wow, you've seen all of the exhibits!\nWhich was your favorite?";
        UICanvas.SetActive(true);
        controller.isPaused = true;
    }

    void build_stim(List<(uint, string, float)> trial_params)
    {

        foreach (GameObject bp in blurPaintings)
            Destroy(bp);
        blurPaintings.Clear();

        foreach (GameObject cp in clearPaintings)
            Destroy(cp);
        clearPaintings.Clear();

        for (int i = 1; i <= 8; i++)
        {
            GameObject blurred = painting(
                x: (float)Sin(4 * PI * i / 18) / 2 * 15,
                z: (float)Cos(4 * PI * i / 18) / 2 * 15,
                theta: 40 * i,
                imgpath: trial_params[i - 1].Item2,
                blur: trial_params[i - 1].Item3
            );

            // Clarified paintings. In the far end alcove of each arm.
            GameObject clarified = painting(
                //     offset   x/z ratio      *  3/2 width of hall
                x: (float)Sin(4 * PI * i / 18) / 2 * 15 * 5.5f + (float)(Cos(4 * PI * i / 18) * 1.45 * Sin(PI / 18) * 15),
                z: (float)Cos(4 * PI * i / 18) / 2 * 15 * 5.5f - (float)(Sin(4 * PI * i / 18) * 1.45 * Sin(PI / 18) * 15),
                theta: 40 * i + 90,
                imgpath: trial_params[i - 1].Item2,
                y: 1.5f
            );

            // No collider.
            Destroy(blurred.GetComponent<Collider>());
            spotlight(blurred);
            spotlight(clarified);
            blurPaintings.Add(blurred);
            clearPaintings.Add(clarified);
        }
    }

    public override string ToString()
    {
        return $"trial: {trial}, init: {t_init}, onset: {t_trial_onset}, stimuli: {stimuli.Count}";
    }

}