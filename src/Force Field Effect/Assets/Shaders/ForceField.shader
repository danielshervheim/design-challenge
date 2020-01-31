Shader "ForceField"
{
    Properties
    {
        // Blends smoothly from 0 to 1 as the shield turns on/off.
        [HideInInspector]
        _Timer("On/Off Timer", Range(0.0, 1.0)) = 0.0

        [HideInInspector]
        [Enum(Off,0,Front,1,Back,2)]
        _Cull ("Cull", Int) = 2

        // Blends smoothly from 1 to 0 as the player approaches the shield boundary.
        [HideInInspector]
        _CullFade("Cull Fade", Range(0.0, 1.0)) = 1.0

        [Header(Common)]
        [NoScaleOffset] _DistortionTexture("Distortion Texture", 2D) = "black" {}

        [Header(Vertex)]
        _VertexOffsetScale("Offset Scale", Vector) = (1,1,0,0)
        _VertexOffsetStrength("Offset Amplitude", float) = 0.1

        [Header(Fragment)]
        _DistortionScale ("Distortion Scale", Vector) = (1, 1, 0, 0)
        _DistortionStrength("Distortion Amplitude", Range(0,0.01)) = 0.005
        [HDR] _PrimaryColor("Color (Primary)", Color) = (1,1,1,1)
        [HDR] _SecondaryColor("Color (Secondary)", Color) = (1,1,1,1)
        _FresnelFalloff("Fresnel Falloff", float) = 5
    }
    SubShader
    {
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Cull [_Cull]
        ZWrite Off

        Tags
        {
           "Queue" = "Transparent"
           "RenderType" = "Transparent"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 grabPosition : TEXCOORD3;
            };

            // Depth and color buffers.
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;

            float _Timer;
            uint _Cull;
            float _CullFade;
            sampler2D _DistortionTexture;

            // Vertex options.
            float2 _VertexOffsetScale;
            float _VertexOffsetStrength;

            // Fragment options.
            float2 _DistortionScale;
            float _DistortionStrength;
            float3 _PrimaryColor;
            float3 _SecondaryColor;
            float _FresnelFalloff;

            float GetSwirlMask(float2 uv, float speed, float amplitude)
            {
                return abs(2 * frac((uv.x + uv.y + _Time.y/speed) * amplitude) - 1);
            }

            v2f vert (appdata v)
            {
                v2f o;

                // Offset the vertex in the normal direction by a set of masks.
                float4 texUV = float4(v.uv * _VertexOffsetScale + _Time.yy, 0, 0);
                float offset = length(tex2Dlod(_DistortionTexture, texUV).rg);  // Offset by random noise from a texture.
                offset += GetSwirlMask(v.uv, 5, 5);  // Offset by a swirl mask (spinning top effect).
                offset *= (1 - _Timer);  // Fade the strength off as the field turns off.
                offset *= (1 - v.uv.y);  // Fade the strength off near the top. This is to avoid ugly pinching artifacts.
                offset *= _VertexOffsetStrength;
                v.vertex.xyz += v.normal*offset;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(UNITY_MATRIX_M, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.grabPosition = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // A swirl pattern, like a spinning top.
                float mask_swirl = GetSwirlMask(i.uv, 5, 5);

                // A smooth gradient from the base of the sphere to the top.
                float mask_height = saturate(i.uv.y);

                float glowStrength = _FresnelFalloff + sin(_Time.y);

                // Highlights the edges of the sphere.
                float3 viewDirection = normalize(i.worldPosition - _WorldSpaceCameraPos);
                viewDirection *= (_Cull==1) ? -1 : 1;
                float mask_fresnel = pow(1 + dot(viewDirection, i.worldNormal), glowStrength);

                // A thin band along the base that follows the sphere as it retracts.
                float mask_floor = pow(1 - mask_height + _Timer, 10*glowStrength);

                // Calculate the position of this fragment in screen space to
                // use as uv's in screen-space texture look ups.
                float2 screenCoord = i.grabPosition.xy / i.grabPosition.w;

                // Offset the screen coordinate
                float2 offsetTex = tex2D(_DistortionTexture, i.uv*_DistortionScale + _Time.yy).rg;
                offsetTex += mask_swirl.xx;

                // Sample the grab-pass and depth textures based on the screen coordinate
                // to get the frag color and depth of the fragment behind this one.
                float3 fragColor = tex2D(_CameraOpaqueTexture, screenCoord.xy + offsetTex*_DistortionStrength).rgb;
                float fragDepth = tex2D(_CameraDepthTexture, screenCoord.xy + offsetTex*_DistortionStrength).x;

                // White where the force field is on, black where its off.
                float mask_off = (1 + mask_height - _Timer);
                mask_off += tex2D(_DistortionTexture, float2(i.uv.x*5, 0) + _Time.yy/5).x * 0.25 * (1 - _Timer);
                mask_off = floor(saturate(mask_off));

                // 1 where objects intersect the force field, tapers away to 0.
                float mask_depth = LinearEyeDepth(fragDepth) - LinearEyeDepth(i.vertex.z);
                mask_depth = saturate(exp(-mask_depth*glowStrength));

                // Tint the scene with the secondary color
                float3 color = fragColor * lerp(_SecondaryColor, 1, mask_fresnel);

                // Add the primary color based on the masks.
                color = lerp(color, _PrimaryColor, saturate(mask_fresnel + mask_floor + mask_depth));

                return float4(color, mask_off * _CullFade);
            }
            ENDCG
        }
    }
}
