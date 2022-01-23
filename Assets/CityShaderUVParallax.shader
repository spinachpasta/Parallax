Shader "Custom/CityShaderUVParallax"
{
    Properties {
        _Ilum("ilum", 2D) = "black"{}
        _Specular("specular", 2D) = "black"{}
        _Color("Main Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _ForwardTex ("Forward", 2D) = "clear" {}
        _BackWardTex ("BackWard", 2D) = "clear" {}
        _GroundTex ("Ground", 2D) = "clear" {}
        _Normal ("Normal", 2D) = "white" {}
        _Forward("Forward",Float)=0.5
        _Backward("Backward",Float)=0.5
        _Marching("Marching",Float)=0.1
    }
    SubShader {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        LOD 200
        CGPROGRAM
        #pragma target 3.0
        #pragma surface surf Lambert
        
        sampler2D _Specular;
        sampler2D _Ilum;
        fixed4 _Color;
        sampler2D _MainTex;
        sampler2D _ForwardTex;
        sampler2D _BackWardTex;
        sampler2D _Normal;
        sampler2D _GroundTex;
        float _Forward;
        float _Backward;
        float _Marching;
        
        struct Input {
            float4 color : COLOR;
            float3 worldNormal; // This will hold the vertex normal
            float3 worldPos;
            float4 screenPos;
            float3 viewDir;
            float2 uv_MainTex;
        };
        
        float3x3 inverse(float3x3 m) {
             float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2];
             float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2];
             float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2];

             float b01 = a22 * a11 - a12 * a21;
             float b11 = -a22 * a10 + a12 * a20;
             float b21 = a21 * a10 - a11 * a20;

             float det = a00 * b01 + a01 * b11 + a02 * b21;

             return float3x3(b01, (-a22 * a01 + a02 * a21), (a12 * a01 - a02 * a11),
                          b11, (a22 * a00 - a02 * a20), (-a12 * a00 + a02 * a10),
                          b21, (-a21 * a00 + a01 * a20), (a11 * a00 - a01 * a10)) / det;
        }
        float3x3 getCorrection(float3 n,float3 up){
            //float3 xaxis=cross(n,up);
            float3 zaxis = n;
            float3 xaxis = (cross(up, zaxis));
            float3 yaxis = cross(zaxis, xaxis);
            return inverse(float3x3(
                xaxis.x,yaxis.x,zaxis.x,
                xaxis.y,yaxis.y,zaxis.y,
                xaxis.z,yaxis.z,zaxis.z
            ));
        }
        void surf (Input IN, inout SurfaceOutput o) {
            float3 vd=IN.viewDir;
            vd=mul(getCorrection(IN.worldNormal,float3(0,1,0)),vd);
            //vd=normalize(vd);
            float2 vShift=vd.xy;
            vShift/=vd.z;
            vShift.y*=-1;
            //o.Albedo=tex2D(_MainTex,IN.uv_MainTex+vd.xy);
            
            float2 uvg=vd.xz/vd.y;
            float2 buv=IN.uv_MainTex+vShift*(_Backward+_Forward);
            uvg.x*=buv.y;
            uvg.y*=buv.y;
            uvg.x+=buv.x;
            half4 c3 = tex2D (_BackWardTex,buv);
            c3=c3* step(0,IN.worldPos.y)+step(IN.worldPos.y,0)*tex2D (_GroundTex,uvg);
            //half4 c1 = step(0,uvf.y) * tex2D (_ForwardTex,uvf) + step(uvf.y,0) * tex2D (_GroundTex,uvg);
            half4 c =c3;
            float Marching=max(0.0001,_Marching);
           
            for(float i=Marching;i<_Backward;i+=Marching){
                float r= i/_Backward;
                float2 uv=buv-i*vShift;
                half4 c2 = step(0,uv.y) * tex2D (_MainTex,uv);
                c=c*step(c2.a,r)+c2*step(r,c2.a);
                //uvw+=_Marching*vShift*_Backward;
            }

            half3 normal=half3(0,0,1);
            for(float i=Marching;i<_Forward;i+=Marching){
                float r= i/_Forward;
                float2 uv=buv-(i+_Backward)*vShift;
                half4 c1 = step(0,uv.y) * tex2D (_ForwardTex,uv);
                half3 n1=tex2D(_Normal,uv);
                half s1=step(c1.a,r);
                c=c*s1+c1*(1-s1);
                normal=normal*s1+n1*(1-s1);
                //c=c*(1-c1.a)+c1*c1.a;
            }
            
            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
            //o.Albedo=vd.xyz;
            o.Albedo = (tex2D(_Specular, screenUV).rgb*0.1+ _Color.rgb *c.rgb);//c.rgb * IN.color.rgb; // vertex RGB
            o.Alpha = c.a * IN.color.a; // vertex Alpha
            o.Emission =tex2D(_Ilum, IN.uv_MainTex+vShift*(_Forward+_Backward)).rgb*0.5f;
            //o.Normal=normal;//tex2D(_Normal,uvf).xyz;
        }
        ENDCG
    } 
    Fallback "Diffuse"
}
