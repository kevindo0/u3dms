Shader "Custom/NormalMapTangentSpace"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bump Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", float) = 1
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(1.0, 256)) = 6
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


            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Color;
            float4 _Specular;
            float _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.xy = TRANSFORM_TEX(v.vertex, _MainTex);
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // // 求副切线：法线和切线的点乘得到了副切线方向有两个，用*w分量来选择正面
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                // // 计算从模型空间到切线空间的旋转矩阵
                // float3x3 rotation = fixed3x3(v.tangent.xyz, binormal, v.normal);

                // ** 或使用cg.cginc中的内置宏 **
                TANGENT_SPACE_ROTATION;
                
                // 函数 ObjSpaceLightDir 和 ObjSpaceViewDir 来得到模型空间下的光照和视角方向
                // 模型空间到切线空间的变换 切线空间中顶点到光源向量
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                // 模型空间到切线空间的变换 切线空间中顶点到摄像机向量
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 切线空间下灯光的单位向量
                float3 tangentLightDir = normalize(i.lightDir);
                // 切线空间下摄像机的单位向量
                float3 tangentViewDir = normalize(i.viewDir);
                // 在法线贴图中得到贴图
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                // // 图片格式未设置成Normal Map
                // fixed3 tangentNormal;
                // tangentNormal.xy = (packedNormal.xy * 2 - 1)* _BumpScale;
                // // 由于法线都是单位向量， 因此tangentNormal.z 分量可以通过tangentNormal.xy 计算而来
                // // 因为法线是归一化的，因此满足x2 + y2 + z2 = 1 所以z=sqrt(1-(x2+y2));
                // tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 图片格式设置成Normal Map
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;


                // 环境光颜色 * albedo
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 漫反射Diffuse颜色
                float3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
                
                // 中线 : 点到灯光的方向 + 点到摄像机的方向
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
