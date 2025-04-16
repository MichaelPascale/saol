// BehaviorLogger.cs, Copyright (c) 2025, Michael Pascale.
// SPDX-License-Identifier: MIT

using UnityEngine;
using Apache.Arrow;
using Apache.Arrow.Ipc;
using System.IO;
using Parquet.Serialization;
using System.Threading.Tasks;
using System.Collections.Generic;
using UnityEngine.UIElements;
using UnityEditor.Rendering.Universal;
using SAOL;


struct FrameRecord {
    public double d;
    public FrameRecord(double d)
    {
        this.d = d;
    }
}
/* 
 * NOTE: Set the execution order for this behaviour to occur after other scripts.
 * See Edit > Project Setttings > Script Execution Order
 */
public class BehaviorLogger : MonoBehaviour
{

    public GameObject player;
    private InputSystem_Actions controls;
    private List<FrameRecord> records;

    public void Start()
    {
        records = new List<FrameRecord>();
        controls = new InputSystem_Actions();
        controls.Enable();
        controls.Player.SaveKeyShortcut.performed += _ => save();
    }

    // Update is called once per frame
    void Update()
    {
        records.Add(new FrameRecord(Time.timeAsDouble));
    }

    async void save()
    {
        Debug.Log("Save initiated. Writing records from " + records.Count + " frames.");
        await ParquetSerializer.SerializeAsync(records, Path.Combine(Application.persistentDataPath, System.DateTime.UtcNow.ToString("'PoseData_'yyyyMMdd'T'HHmmss'Z.parquet'")), SAOL.Options.PARQUET_OPS);
        Debug.Log("Written out to " + Application.persistentDataPath);
        records.Clear();
    }
}
