/* effortful.cs
 * WASD controls. Speed is proportional to rate of key press.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * MIT Licensed.
 */
using System;
using System.Collections.Generic;
using System.Linq;
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
    private double effort_rate_scaled = 0;
    private double effort_rate_max = 0;

    void Start()
    {
        controller = GetComponent<CharacterController>();

        effort_action = new InputAction("SAOLForwardEffortful");
        effort_action.AddBinding("<Keyboard>/w");
        effort_action.AddBinding("<Gamepad>/buttonSouth");

        effort_action.started += ctx => {
            double diff = ctx.time - effort_last_t;
            effort_last_t = ctx.time;

            // Discard keypresses more than one second old.
            if (diff > 1)
            {
                effort_recent_ds.Clear();
                effort_rate = 0.25;
                return;
            }

            // Keep only the last N_RECENT keypresses.
            while (effort_recent_ds.Count >= N_RECENT)
                effort_recent_ds.Dequeue();
            
            effort_recent_ds.Enqueue(diff);
            effort_rate = 1/Math.Min(effort_recent_ds.Average(), 1);

            if (effort_rate > effort_rate_max)
                effort_rate_max = effort_rate;

            effort_rate_scaled = effort_rate / effort_rate_max;

            Debug.Log($"n = {effort_recent_ds.Count}, last rt = {diff, 5:F3}, avg rate = {effort_rate, 5:F3}, scaled rate = {effort_rate_scaled}");
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
        
        effort_rate = Mathf.Lerp((float)effort_rate, 0, Time.deltaTime * 5f);

        // Move the character
        Vector3 move = transform.forward * moveZ * (float) effort_rate_scaled * moveSpeed;
        
        // Apply movement
        controller.Move(move * Time.deltaTime);

        // Rotate character left/right
        float rotation = moveX * rotationSpeed * Time.deltaTime;
        transform.Rotate(0, rotation, 0);
    }
}
