using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CustomFogImageEffect : MonoBehaviour {

    // Import
    [Header("Import")]
    [SerializeField] private Shader shaderFog;
    [SerializeField] private Shader shaderBlur;
    [SerializeField] private Shader shaderDepthBlur;
    private Material material0;
    private Material material1;
    private Material material2;
    private new Camera camera;

    // Fog
    [Header("Fog")]
    [SerializeField] private Color fog0Color;
    [SerializeField] private Color fog1Color;
    [SerializeField] private float heightPower = 100;
    [SerializeField] private float heightOffset = -50;
    [SerializeField][Range(0.0f, 1.0f)] private float power = 1;

    // Fog falloff
    [Header("Fog falloff")]
    [SerializeField] private int resolution = 512;
    [SerializeField] private AnimationCurve falloff;

    // Blur
    [Header("Blur")]
    [SerializeField] private int blurDownRes;
    [SerializeField] private int blurIterations;
    [SerializeField] private Color blurColor;

    // Blur falloff
    [Header("Blur falloff")]
    [SerializeField]
    private int blurFalloffResolution;
    [SerializeField] private AnimationCurve blurFalloff;



    private void OnEnable() {
        // Setup
        material0 = new Material(shaderFog);
        material1 = new Material(shaderDepthBlur);
        material2 = new Material(shaderBlur);
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.Depth;
    }



    void OnRenderImage(RenderTexture src, RenderTexture dst) {
        // Falloff
        Texture2D blurFalloffTexture = new Texture2D(blurFalloffResolution, 1);
        for (int x = 0; x < blurFalloffResolution; x++) {
            blurFalloffTexture.SetPixel(x, 0, Color.white * (1f - blurFalloff.Evaluate((float)x / blurFalloffResolution)));
        }
        blurFalloffTexture.Apply();
        blurFalloffTexture.wrapMode = TextureWrapMode.Clamp;

        Texture2D falloffTexture = new Texture2D(resolution, 1);
        for (int x = 0; x < resolution; x++) {
            falloffTexture.SetPixel(x, 0, Color.white * (1f - falloff.Evaluate((float)x / resolution)));
        }
        falloffTexture.Apply();
        falloffTexture.wrapMode = TextureWrapMode.Clamp;


        // Blur
        int width = src.width >> blurDownRes;
        int height = src.height >> blurDownRes;

        material1.SetColor("_Tint", blurColor);
        material1.SetTexture("_Falloff", blurFalloffTexture);

        RenderTexture rt = RenderTexture.GetTemporary(width, height);
        Graphics.Blit(src, rt);

        for (int i = 0; i < blurIterations; i++) {
            RenderTexture rt2 = RenderTexture.GetTemporary(width, height);
            Graphics.Blit(rt, rt2, i == 0 ? material1 : material2);
            RenderTexture.ReleaseTemporary(rt);
            rt = rt2;
        }


        // Fog
        material0.SetColor("_Fog0Color", fog0Color);
        material0.SetColor("_Fog1Color", fog1Color);
        material0.SetFloat("_HeightPower", heightPower);
        material0.SetFloat("_HeightOffset", heightOffset);
        material0.SetFloat("_BlurDepthPow", power);
        material0.SetTexture("_Falloff", falloffTexture);

        Matrix4x4 p = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        p[2, 3] = p[3, 2] = 0.0f;
        p[3, 3] = 1.0f;
        Matrix4x4 clipToWorld = Matrix4x4.Inverse(p * camera.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -p[2, 2]), Quaternion.identity, Vector3.one);
        material0.SetMatrix("clipToWorld", clipToWorld);

        // Done
        material0.SetTexture("_BlurDepth", rt);
        Graphics.Blit(src, dst, material0);
        RenderTexture.ReleaseTemporary(rt);
    }
}
