/* effortful.cs
 * WASD controls. Speed is proportional to rate of key press.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * MIT Licensed.
 */
using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Text;
using System.IO.Compression;
using UnityEngine;
using UnityEngine.InputSystem;


//https://docs.unity3d.com/Packages/com.unity.inputsystem@1.12/manual/timing-and-latency.html
public class EffortfulControl : MonoBehaviour 
{
    public float moveSpeed = 8f;
    public float rotationSpeed = 100f;

    public bool isPaused = false;


    private CharacterController controller;

    const int N_RECENT = 10;
    private InputAction effort_action;
    private Queue<double> effort_recent_ds = new Queue<double>(N_RECENT);
    private double effort_last_t = 0;
    private double effort_rate = 0;
    private double effort_rate_max = 1;
    private bool recording = false;

    public const int PREALLOC_SIZE_LOG = 216000;
    private List<double> response_data = new List<double>(PREALLOC_SIZE_LOG);

    void Start()
    {
        controller = GetComponent<CharacterController>();

        

        effort_action = new InputAction("SAOLEffortRTKey");
        effort_action.AddBinding("<Keyboard>/enter");
        effort_action.AddBinding("<Gamepad>/buttonSouth");

        effort_action.started += ctx => {            
            double diff = ctx.time - effort_last_t;
            effort_last_t = ctx.time;

            // Discard keypresses more than one second old.
            if (diff > 1)
            {
                effort_recent_ds.Clear();
                effort_rate = 0;
                return;
            }

            // Keep only the last N_RECENT keypresses.
            while (effort_recent_ds.Count >= N_RECENT)
                effort_recent_ds.Dequeue();
            
            effort_recent_ds.Enqueue(diff);
            effort_rate = 1/Math.Min(effort_recent_ds.Average(), 1);

            if (effort_rate > effort_rate_max)
                effort_rate_max = effort_rate;

            if (recording)
                response_data.Add(ctx.time);

            Debug.Log($"n = {effort_recent_ds.Count}, last rt = {diff, 5:F3}, avg rate = {effort_rate, 5:F3}, scaled rate = {effort_rate / effort_rate_max}");
        };

        effort_action.Enable();
    }

    void Update()
    {
        // Get movement input
        float moveX = Input.GetAxis("Horizontal"); // Left and Right Arrow keys (A/D)
        float moveZ = Input.GetAxis("Vertical");   // Up and Down Arrow keys (W/S)

        if (isPaused)
            return;

        // Move the character
        Vector3 move = transform.forward * moveZ * (float) (effort_rate/effort_rate_max) * moveSpeed;

        // While the effort key has not been pressed, decay the press-rate.
        effort_rate *= Mathf.Pow(0.5f, Time.deltaTime * 4);
        if (effort_rate < 0.1)
            effort_rate = 0;
        
        // Apply movement
        controller.Move(move * Time.deltaTime);

        // Rotate character left/right
        float rotation = moveX * rotationSpeed * Time.deltaTime;
        transform.Rotate(0, rotation, 0);
    }

    public void save(string path)
    {
        if (!path.EndsWith(".tsv.gz"))
            throw new ArgumentOutOfRangeException("Provided filename must have extension 'tsv.gz'.");

        using (FileStream stream = File.Create(Path.Combine(Application.persistentDataPath, path)))
        using (GZipStream compressor = new GZipStream(stream, System.IO.Compression.CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(compressor, Encoding.UTF8))
        {
            writer.WriteLine("time");
            foreach (double t in response_data)
                writer.WriteLine(t);
        }
    }

    public void record()
    {
        response_data.Clear();
        recording = true;
    }

    public void stop_record()
    {
        recording = false;
    }
}
