/* VoyeeXBoxController.cs
 * Our Voyee Wired 360 (HY4102) controllers exhibited problems on MacOS, either
 * not detected or with the vertical axis flipped. This code registers a new
 * controller layout for the generic human interface device, following:
 *   https://docs.unity3d.com/Packages/com.unity.inputsystem@1.13/manual/HID.html
 * 
 * The new layout inherits from the XboxGamepadMacOS with the exception
 * that the y-axis of the left vertical stick has the invert processor added.
 *
 * Note that SAOL only uses buttonSouth and leftStick at this time. The other controls
 * on the gamepad are not modified and have not been tested.
 *
 * Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
 * SPDX-License-Identifier: MIT
 */

// The gamepad's driver seems to work fine on Linux. Compile only for MacOS.
#if UNITY_EDITOR_OSX || UNITY_STANDALONE_OSX
using UnityEngine;
using UnityEditor;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Layouts;
using UnityEngine.InputSystem.XInput;

[InputControlLayout(displayName = "Voyee Third-Party XBox Controller (XboxGamepadMacOS)")]
#if UNITY_EDITOR
[InitializeOnLoad]
#endif
public class VoyeeXBoxController : XboxGamepadMacOS
{
    static VoyeeXBoxController()
    {
        InputSystem.RegisterLayout<VoyeeXBoxController>(
            matches: new InputDeviceMatcher()
            // NOTE: The device's HID is technically Microsoft Corporation / Xbox360 Controller.
            .WithCapability("vendorId", 0x45E)
            .WithCapability("productId", 0x28E)
        );
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    static void Init()
    {}

    protected override void FinishSetup()
    {
        base.FinishSetup();
        leftStick.y.invert = false;
    }
}
#endif
