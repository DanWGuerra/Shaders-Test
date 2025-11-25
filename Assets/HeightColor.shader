Shader "Custom/HeightColor"
{
    Properties
    {
        _Color1("Bottom Color", Color) = (1,0,0,1)
        _Color2("Mid Color", Color) = (0,1,0,1)
        _Color3("Upper Color", Color) = (0,0,1,1)
        _Color4("Top Color", Color) = (1,1,1,1)
        _MinHeight("Min Height", Float) = 0
        _MaxHeight("Max Height", Float) = 2
        _Smoothness("Smoothness", Range(0,1)) = 0.2
    }

    SubShader
    {
        Tags{"RenderPipeline"="UniversalRenderPipeline"}
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            float3 _Color1, _Color2, _Color3, _Color4;
            float _MinHeight, _MaxHeight, _Smoothness;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vPos = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = vPos.positionCS;
                OUT.positionWS = vPos.positionWS;
                return OUT;
            }

            float3 LerpSmooth(float3 a, float3 b, float t, float smooth)
            {
                t = saturate((t - smooth) / (1 - 2*smooth));
                return lerp(a, b, saturate(t));
            }

            float4 frag (Varyings IN) : SV_Target
            {
                float height = IN.positionWS.y;
                float t = saturate((height - _MinHeight) / (_MaxHeight - _MinHeight));

                float c1 = step(t, 0.33);
                float c2 = step(0.33, t) * step(t, 0.66);
                float c3 = step(0.66, t) * step(t, 1.0);
                float c4 = step(1.0, t);

                float3 col;

                if (t < 0.33)
                    col = LerpSmooth(_Color1, _Color2, t / 0.33, _Smoothness);
                else if (t < 0.66)
                    col = LerpSmooth(_Color2, _Color3, (t - 0.33)/0.33, _Smoothness);
                else
                    col = LerpSmooth(_Color3, _Color4, (t - 0.66)/0.33, _Smoothness);

                return float4(col, 1);
            }
            ENDHLSL
        }
    }
}
