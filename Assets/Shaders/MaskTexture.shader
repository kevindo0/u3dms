// 遮罩纹理
Shader "Custom/MaskTexture"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Bump Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", float) = 1
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", float) = 6
        _SpecularMask("Specular Mask", 2D) = "white" {}
        _SpecularScale("Specular Scale", float) = 1
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float2 maskUv : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _Specular;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float _Gloss;
            sampler2D _SpecularMask;
            float4 _SpecularMask_ST;
            float _SpecularScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.maskUv = TRANSFORM_TEX(v.texcoord, _SpecularMask);

                TANGENT_SPACE_ROTATION;

                // 灯光方向 模型空间转切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                // 视角方向 模型空间转切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 lightDir = normalize(i.lightDir);
                fixed3 viewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, lightDir));
                
                // 高光遮罩
                fixed3 specularMask = tex2D(_SpecularMask, i.maskUv) * _SpecularScale;

                // 高光反射
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
                specular *= specularMask;

                fixed3 col = ambient + diffuse + specular;
                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
