Shader "OMAGX Studios/Sky"
{
    Properties
    {
		_HorizonC("Horizon Color", Color) = (0.7,0.8,1,1)
		_SkyC("Sky Color", Color) = (0,0.45,1,1)
		_CloudCol("Cloud Color", Color) = (1,1,1,1)
		_MountainCol("Mountains Color", Color) = (1,1,1,1)
		_GroundCol("Ground Color", Color) = (1,1,1,1)
		_StarCol("Star Color", Color) = (1,1,1,1)
        _MainTex ("Cloud Texture", 2D) = "white" {}
		_StarTex("Stars Texture", 2D) = "white" {}
		_MountainTex("Horizon Mountains", 2D) = "white" {}
		_GroundMask("Ground Mask", 2D) = "white" {}
		_StarTiling("Stars Tiling", Float) = 1
		_HorizonShift("Gradient Adjust", Range(0,1)) = 1
		_CloudOpacity("Cloud Opacity", Range(0,1)) = 1
		_RotationSpeed("Cloud Rotation", Float) = 0
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float2 uv3 : TEXCOORD2;
				float4 color : COLOR;
            };

            struct v2f
            {
				//init UVs
                float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;

                float4 vertex : SV_POSITION;
				float4 color : COLOR;

				//world space coordinates
				half3 objNormal : TEXCOORD2;
				float3 worldCoords : TEXCOORD3;

				//ground texture/color uv
				float2 uv3 : TEXCOORD4;
            };

            sampler2D _MainTex, _StarTex, _MountainTex;
			sampler2D _GroundMask;
            float4 _MainTex_ST;
			float4 _GroundMask_ST, _MountainTex_ST;
			fixed4 _HorizonC, _SkyC, _CloudCol, _MountainCol;
			fixed4 _GroundCol, _StarCol;
			float _HorizonShift, _CloudOpacity, _StarTiling;
			float _RotationSpeed;

            v2f vert (appdata v, float3 normal : NORMAL, float4 pos : POSITION)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldCoords = pos.xyz * (_StarTiling * 0.001);
				o.objNormal = normal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv3 = TRANSFORM_TEX(v.uv3, _GroundMask);
				
				//consistent spinning of cloud texture
				o.uv = o.uv * 2 - 1;
				float c = cos(_RotationSpeed * _Time.y);
				float s = sin(_RotationSpeed * _Time.y);

				float2x2 mat = float2x2(c, -s, s, c);
				o.uv = mul(mat, o.uv);

				o.uv = o.uv * 0.5 - 0.5;

				o.uv2 = TRANSFORM_TEX(v.uv2, _MountainTex);
				o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
				fixed4 base = lerp(_SkyC, _HorizonC, (1.0-i.color.r) * _HorizonShift);
				fixed4 cloudlayer = tex2D(_MainTex, i.uv) * _CloudCol;
				fixed4 mountainlayer = tex2D(_MountainTex, i.uv2) * _MountainCol;
				fixed4 groundlayer = tex2D(_GroundMask, i.uv3);
	
				fixed4 starlayer = tex2D(_StarTex, i.worldCoords.xz);

				fixed4 stars_combined = base + ((_StarCol * starlayer.r) * _StarCol.a);

				fixed4 clouds_combined = lerp(stars_combined, cloudlayer, cloudlayer.a * _CloudOpacity);

				fixed4 mountains_combined = lerp(clouds_combined, mountainlayer, mountainlayer.a);

				fixed4 col = lerp(mountains_combined, _GroundCol, groundlayer.r);

				
                return col;
            }
            ENDCG
        }
    }
}
