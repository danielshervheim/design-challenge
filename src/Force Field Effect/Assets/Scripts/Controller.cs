using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Controller : MonoBehaviour
{
    public ForceField forceField;
    public Transform camera;

    public Transform pedestal;
    private bool grab;

    private float pitch = 0f;
	private float yaw = 0f;

	public float moveSpeed = 1f;
	public float lookSpeed = 1f;

    void Update()
    {
        Vector3 forward = Vector3.Normalize(Vector3.Scale(transform.forward, new Vector3(1f, 0f, 1f)));
		Vector3 right = Vector3.Normalize(Vector3.Scale(transform.right, new Vector3(1f, 0f, 1f)));
		transform.position += (forward*Input.GetAxis("Vertical") + right*Input.GetAxis("Horizontal")) * moveSpeed * Time.deltaTime;

        pitch -= Input.GetAxis("Mouse Y") * lookSpeed;
        yaw += Input.GetAxis("Mouse X") * lookSpeed;
        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);

        if (Input.GetKeyDown(KeyCode.P))
        {
            grab = !grab;
            if (grab)
            {
                pedestal.parent = camera;
            }
            else
            {
                pedestal.parent = null;
            }
        }

        if (Input.GetKeyDown(KeyCode.O))
        {
            forceField.on = !forceField.on;
        }
        Cursor.visible = false;
    }
}
