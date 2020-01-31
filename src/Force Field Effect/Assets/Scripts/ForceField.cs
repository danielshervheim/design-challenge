using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ForceField : MonoBehaviour
{
    public Material forceFieldMaterial;

    public bool on = true;

    [Tooltip("The shield will turn on/off in this amount of time (s).")]
    public float duration = 1f;
    public AnimationCurve easingCurve;

    [Tooltip("The shield will fade out whenever the player gets nearer than this distance to the shield boundary.")]
    public float fadeDistance = 0.25f;

    private float timer = 0f;
    private Transform player;

    // Update is called once per frame
    void Update()
    {
        if (forceFieldMaterial == null)
        {
            return;
        }

        if (player == null)
        {
            player = Camera.main.transform;
        }

        // Increment and set the on/off timer in the material. This acts as a
        // measure of whether the shield is on or off (and can be used to animate)
        // on/off effects within the shader.
        if (on)
        {
            timer -= Time.deltaTime / duration;
        }
        else
        {
            timer += Time.deltaTime / duration;
        }
        timer = Mathf.Clamp01(timer);
        forceFieldMaterial.SetFloat("_Timer", Mathf.Clamp01(easingCurve.Evaluate(timer)));

        // If the player is near the shield boundary, fade it out so there are no glaring
        // popping effects when the cull mode is changed.
        float delta = Mathf.Abs(Vector3.Distance(player.position, transform.position) - transform.localScale.x);
        if (delta < fadeDistance)
        {
            forceFieldMaterial.SetFloat("_CullFade", delta/fadeDistance);
        }
        else
        {
            forceFieldMaterial.SetFloat("_CullFade", 1f);
        }

        // If the player is inside the shield, insure that front-face culling is turned on.
        // Otherwise, do standard back-face culling.
        if (Vector3.Distance(player.position, transform.position) < transform.localScale.x)
        {
            if (forceFieldMaterial.GetInt("_Cull") != 1)
            {
                forceFieldMaterial.SetInt("_Cull", 1);
            }
        }
        else
        {
            if (forceFieldMaterial.GetInt("_Cull") != 2)
            {
                forceFieldMaterial.SetInt("_Cull", 2);
            }
        }
    }
}
