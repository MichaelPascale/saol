/* effortful.cs
 * WASD controls. Speed is proportional to rate of key press.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * MIT Licensed.
 */
using System.Linq;
using TMPro;
using Unity.VisualScripting.FullSerializer;
using UnityEngine;
using UnityEngine.InputSystem;
using ZstdSharp.Unsafe;



public class EffortfulKeyboardControls : MonoBehaviour 
{
    public float moveSpeed = 5f;
    public float rotationSpeed = 200f;

    public bool isPaused = false;



    private CharacterController characterController;
    private Vector3 moveDirection = Vector3.zero;

    // For taking the moving average keypress rate.
    const uint FRAMES = 60;
    private bool _last_frame_press; // Was there a keypress on the previous frame?
    private float _t_last_press; // At what time did the last keypress occur?
    private float[] _ts_recent_presses = new float[FRAMES]; // Times of the last 60 frames (1s).
    private uint _i_recent_presses = 0;

    void Start()
    {
        characterController = GetComponent<CharacterController>();
    }

    void Update()
    {
        // Get movement input
        float moveX = Input.GetAxis("Horizontal"); // Left and Right Arrow keys (A/D)
        float moveZ = Input.GetAxis("Vertical");   // Up and Down Arrow keys (W/S)

        // Debug.Log(moveX + "   " + moveZ);

        if (isPaused)
            return;
        
        if (Input.GetKeyDown(KeyCode.W)) {
            if (_last_frame_press)
            {
                // still same press
                _ts_recent_presses[_i_recent_presses] = 0;
            } else
            {
                // new press, record time
                float t_now = Time.time;
                _ts_recent_presses[_i_recent_presses] = 1;//t_now - _t_last_press;
                _t_last_press = t_now;
                _last_frame_press = true;
            }
        }
        else {
            // end press
            _last_frame_press = false;
            _ts_recent_presses[_i_recent_presses] = 0;
        }

        _i_recent_presses = (_i_recent_presses + 1) % FRAMES;

        // Debug.Log(_ts_recent_presses.Sum());
        

        // Move the character
        Vector3 move = transform.forward * _ts_recent_presses.Sum()/8 * moveSpeed;
        
        moveDirection = move;

        // Apply movement
        characterController.Move(moveDirection * Time.deltaTime);

        // Rotate character left/right
        float rotation = moveX * rotationSpeed * Time.deltaTime;
        transform.Rotate(0, rotation, 0);
    }
}
