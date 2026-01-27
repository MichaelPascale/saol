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
    protected DateTime t_init;
    protected void start()
    {
        trial = 0;
        mode = Mode.Running;
        t_init = DateTime.Now;
    }

    protected void stop()
    {
        mode = Mode.Stopped;
    }

    public abstract string cmd_save(string path);
    public abstract string cmd_start();
    public abstract string cmd_stop();

    public override string ToString()
    {
        return mode == Mode.Running ? $"Experiment began at {t_init} (trial {trial}, {DateTime.Now-t_init}s elapsed)." : "No experiment running.";
    }
}