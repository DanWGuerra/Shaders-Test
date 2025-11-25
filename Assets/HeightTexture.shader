Shader "Custom/HeightTextureBlend_Advanced"
{
    Properties
    {
        _Tex1("Bottom Texture", 2D) = "white" {}
        _Tex2("Lower-Mid Texture", 2D) = "white" {}
        _Tex3("Upper-Mid Texture", 2D) = "white" {}
        _Tex4("Top Texture", 2D) = "white" {}

        _Strength1("Bottom Strength", Range(0,1)) = 1
        _Strength2("Lower-Mid Strength", Range(0,1)) = 1
        _Strength3("Upper-Mid Strength", Range(0,1)) = 1
        _Strength4("Top Strength", Range(0,1)) = 1

        _MinHeight("Min Height", Float) = 0
        _MaxHeight("Max Height", Float) = 2
        _Smoothness("Blend Smoothness", Range(0,1)) = 0.15

        // Custom height bands
        _H1("End of Texture 1 (0-1)", Range(0,1)) = 0.25
        _H2("End of Texture 2 (0-1)", Range(0,1)) = 0.50
        _H3("End of Texture 3 (0-1)", Range(0,1)) = 0.75
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes 
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings 
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            // Textures & samplers
            TEXTURE2D(_Tex1); SAMPLER(sampler_Tex1);
            TEXTURE2D(_Tex2); SAMPLER(sampler_Tex2);
            TEXTURE2D(_Tex3); SAMPLER(sampler_Tex3);
            TEXTURE2D(_Tex4); SAMPLER(sampler_Tex4);

            float _MinHeight, _MaxHeight, _Smoothness;
            float _Strength1, _Strength2, _Strength3, _Strength4;
            float _H1, _H2, _H3;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = posInputs.positionCS;
                OUT.positionWS = posInputs.positionWS;
                OUT.uv = IN.uv;

                return OUT;
            }

            // Smooth band transition
            float BandBlend(float t, float start, float end, float smooth)
            {
                return smoothstep(start - smooth, start + smooth, t) *
                       (1.0 - smoothstep(end - smooth, end + smooth, t));
            }

            float4 frag (Varyings IN) : SV_Target
            {
                float height = IN.positionWS.y;
                float t = saturate((height - _MinHeight) / (_MaxHeight - _MinHeight));

                float2 uv = IN.uv;

                // Sample the textures
                float4 c1 = SAMPLE_TEXTURE2D(_Tex1, sampler_Tex1, uv) * _Strength1;
                float4 c2 = SAMPLE_TEXTURE2D(_Tex2, sampler_Tex2, uv) * _Strength2;
                float4 c3 = SAMPLE_TEXTURE2D(_Tex3, sampler_Tex3, uv) * _Strength3;
                float4 c4 = SAMPLE_TEXTURE2D(_Tex4, sampler_Tex4, uv) * _Strength4;

                // Calculate per-band blending
                float w1 = BandBlend(t, 0.0, _H1, _Smoothness);
                float w2 = BandBlend(t, _H1, _H2, _Smoothness);
                float w3 = BandBlend(t, _H2, _H3, _Smoothness);
                float w4 = BandBlend(t, _H3, 1.0, _Smoothness);

                float total = w1 + w2 + w3 + w4 + 1e-6;

                float4 finalColor =
                    (c1 * w1 +
                     c2 * w2 +
                     c3 * w3 +
                     c4 * w4) / total;

                return finalColor;
            }

            ENDHLSL
        }
    }
}
