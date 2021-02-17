Shader "Custom/MyDiffuse"
{
    Properties{
         _Diffuse("Diffuse Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            fixed4 _Diffuse;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed3 color : COLOR;
            };

            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                // 法线方向，把法线方向从模型空间转到世界空间
                float3 normalDir = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                // 光照方向
                // 对于每个顶点来说，光的位置就是光的方向，因为光是平等光
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 漫反射Diffuse颜色 = 直射光颜色 + saturate(cos(光源方向和法线方向夹角))
                fixed3 diffuse = _LightColor0 * saturate(dot(normalDir, lightDir));

                o.color = diffuse * _Diffuse + ambient;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color, 1);
            }
            ENDCG
        }
    }
}
