using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 5f;    // Speed of movement
    public float rotationSpeed = 200f; // Speed of turning
    public float gravity = 9.81f;  // Gravity force

    public bool isPaused = false;

    private CharacterController characterController;
    private Vector3 moveDirection = Vector3.zero;

    void Start()
    {
        characterController = GetComponent<CharacterController>();
    }

    void Update()
    {
        // Get movement input
        float moveX = Input.GetAxis("Horizontal"); // Left and Right Arrow keys (A/D)
        float moveZ = Input.GetAxis("Vertical");   // Up and Down Arrow keys (W/S)

        if (isPaused)
            return;

        // Move the character
        Vector3 move = transform.forward * moveZ * moveSpeed;
        
        // Apply gravity
        // if (characterController.isGrounded)
        // {
            moveDirection = move;
        // }
        // moveDirection.y -= gravity * Time.deltaTime;

        // Apply movement
        characterController.Move(moveDirection * Time.deltaTime);

        // Rotate character left/right
        float rotation = moveX * rotationSpeed * Time.deltaTime;
        transform.Rotate(0, rotation, 0);
    }
}
