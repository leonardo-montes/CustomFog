Shader "Hidden/BlurDepthPass" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _CameraDepthTexture;

			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				UNITY_TRANSFER_DEPTH(o.depth);

				return o;
			}
			
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;

			uniform float4 _Tint;

			float4 box(sampler2D tex, float2 uv, float4 size) {
				float4 c = tex2D(tex, uv + float2(-size.x, size.y)) +  tex2D(tex, uv + float2(0, size.y)) +  tex2D(tex, uv + float2(size.x, size.y)) +
						   tex2D(tex, uv + float2(-size.x, 0)) +       tex2D(tex, uv + float2(0, 0)) +       tex2D(tex, uv + float2(size.x, 0)) +
						   tex2D(tex, uv + float2(-size.x, -size.y)) + tex2D(tex, uv + float2(0, -size.y)) + tex2D(tex, uv + float2(size.x, -size.y));
				return c / 9;
			}

			sampler2D _Falloff;

			fixed4 frag (v2f i) : SV_Target {
				fixed4 col = box(_CameraDepthTexture, i.uv, _MainTex_TexelSize);
				float depth = Linear01Depth(col);

				float fo = 1 - tex2D(_Falloff, float2(depth, 0)).r;

				col = fo * _Tint;
				return col;
			}
			ENDCG
		}
	}
}
