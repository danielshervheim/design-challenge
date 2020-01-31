Shader "Unlit/CrossHatch"
{
    Properties
    {
        [NoScaleOffset] _Stroke1 ("Stroke 1", 2D) = "white" {}
        [NoScaleOffset] _Stroke2 ("Stroke 2", 2D) = "white" {}
        _StrokeScale ("Stroke Scale", float) = 1
        _Curvature ("Curvature", 2D) = "gray" {}

        [Header(Outline)]
        _OutlineDisplacement("Outline Displacement", Range(0.0, 0.01)) = 0.1
        [Toggle] _OutlineRelativeToDistance("Outline Relative to Distance", int) = 1
    }
    SubShader
    {
        LOD 100
        Tags
        {
            "RenderType"="Opaque"
        }

        // Pass 1: outline.
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed _OutlineDisplacement;
            uint _OutlineRelativeToDistance;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                float distFromCamera = length(UnityObjectToViewPos(v.vertex));
                // Sqrt prevents outline from growing too fast.
                float offsetAmount = _OutlineDisplacement * (_OutlineRelativeToDistance ? sqrt(distFromCamera) : 1.0);
                o.vertex = UnityObjectToClipPos(v.vertex+v.normal * offsetAmount);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(0, 0, 0, 1);
            }
            ENDCG
        }

        // Pass 2: main cross hatch effect.
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
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 grabPosition : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.grabPosition = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _StrokeScale;
            sampler2D _Curvature;

            fixed4 frag (v2f i) : SV_Target
            {
                float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));

                // 1 for lit, 0 for shadow. Only areas in shadow recieve cross-hatching.
                float lightMask = round(pow(ndotl, 2));

                // Sample the curvature map to enhance the effect.
                float curvature = tex2D(_Curvature, i.uv).x;
                curvature = saturate(curvature * 20);

                // Calculate the "darkness level" closest to a certain hatch texture.
                float ramp = saturate(ndotl*1.5);
                ramp *= curvature;
                ramp *= 5.0;  // Because there are 6 hatching textures (0...5).

                // Calculate weights based on distance from most closely matching darkness level.
                float w0 = 1-saturate(abs(ramp-0));
                float w1 = 1-saturate(abs(ramp-1));
                float w2 = 1-saturate(abs(ramp-2));
                float w3 = 1-saturate(abs(ramp-3));
                float w4 = 1-saturate(abs(ramp-4));
                float w5 = 1-saturate(abs(ramp-5));
                float sum = w0+w1+w2+w3+w4+w5;

                // Sample the stroke textures.
                float3 stroke1 = tex2D(_Stroke1, i.uv.xy / _StrokeScale).rgb;
                float3 stroke2 = tex2D(_Stroke2, i.uv.xy / _StrokeScale).rgb;

                // Blend each texture based on which most closely matches the darkness of the current fragment.
                float hatching = w5*stroke1.x + w4*stroke1.y + w3*stroke1.z + w2*stroke2.x + w1*stroke2.y + w0*stroke2.z;
                hatching /= sum;

                // Posterize the ndotl for a less "CGI" look.
                float shadowBands = round(ndotl*12)/6;

                // Combine the hatching and shadow bands with the lightmask to get the final tone.
                float tone = lerp(hatching * shadowBands, 1, lightMask) * curvature;
                return fixed4(saturate(tone).xxx, 1);
            }
            ENDCG
        }
    }
}
