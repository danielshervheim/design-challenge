using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Controller : MonoBehaviour
{
    private float pitch = 0f;
	private float yaw = 0f;

	public float moveSpeed = 1f;
	public float lookSpeed = 1f;

    public Transform light;

    private bool lightControl = false;

    private float lightPitch = 0f;
    private float lightYaw = 0f;

    void Start()
    {
        lightPitch = light.rotation.eulerAngles.x;
        lightYaw = light.rotation.eulerAngles.y;
    }

    void Update()
    {
        Vector3 forward = Vector3.Normalize(Vector3.Scale(transform.forward, new Vector3(1f, 0f, 1f)));
		Vector3 right = Vector3.Normalize(Vector3.Scale(transform.right, new Vector3(1f, 0f, 1f)));
		transform.position += (forward*Input.GetAxis("Vertical") + right*Input.GetAxis("Horizontal")) * moveSpeed * Time.deltaTime;
        float y = (Input.GetKey(KeyCode.Space) ? 1f : 0f) - (Input.GetKey(KeyCode.LeftShift) ? 1f : 0f);
        transform.position += Vector3.up * y * moveSpeed * Time.deltaTime;

        if (Input.GetKeyDown(KeyCode.L))
        {
            lightControl = !lightControl;
        }

        if (lightControl)
        {
            lightPitch -= Input.GetAxis("Mouse Y") * lookSpeed;
            lightYaw += Input.GetAxis("Mouse X") * lookSpeed;
        }
        else
        {
            pitch -= Input.GetAxis("Mouse Y") * lookSpeed;
            yaw += Input.GetAxis("Mouse X") * lookSpeed;
        }

        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);
        light.rotation = Quaternion.Euler(lightPitch, lightYaw, 0f);

        Cursor.visible = false;
    }
}
