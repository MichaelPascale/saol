/* Experiment.cs
 * Generic experiment management class.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

using System;
using UnityEngine;

public abstract class SAOLExperiment : MonoBehaviour
{

    public enum Mode { Uninitialized, Stopped, Running }
    protected Mode mode;
    protected uint trial;
    protected uint n_trials;
    protected DateTime t_init;
    protected DateTime t_trial;
    protected double elapsed_s;
    protected double elapsed_trial_s;

    public void Start()
    {
        
    }
    public void Update()
    {
        if (mode != Mode.Running)
            return;

        elapsed_s = DateTime.Now.Subtract(t_init).TotalSeconds;
        elapsed_trial_s = DateTime.Now.Subtract(t_trial).TotalSeconds;
    }

    protected void onstart()
    {
        trial = 0;
        mode = Mode.Running;
        t_init = DateTime.Now;
        elapsed_s = 0;
        
        t_trial = DateTime.Now;
        elapsed_trial_s = 0;
    }

    protected void onstop()
    {
        mode = Mode.Stopped;
    }

    protected void next_trial()
    {
        trial++;

        if (trial == n_trials)
            // FIXME: Implement onend() method to handle this.
            Console.WriteLine("ENDED");

        t_trial = DateTime.Now;
        elapsed_trial_s = 0;
    }

    public abstract string cmd_save(string path);
    public abstract string cmd_start();
    public abstract string cmd_stop();

    public override string ToString()
    {
        return mode == Mode.Running ? $"Experiment began at {t_init} (trial {trial}, {DateTime.Now-t_init}s elapsed)." : "No experiment running.";
    }
}