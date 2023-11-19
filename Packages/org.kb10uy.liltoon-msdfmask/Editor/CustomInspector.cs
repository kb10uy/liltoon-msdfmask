#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using lilToon;

namespace KusakaFactory.LiltoonMsdfMask
{
    public class MsdfMaskInspector : lilToonInspector
    {
        private MaterialProperty _alpha2Mode;
        private MaterialProperty _alpha2Mask;
        private MaterialProperty _alpha2Scale;
        private MaterialProperty _alpha2Value;
        private MaterialProperty _useMsdfMaskAlpha1;
        private MaterialProperty _useMsdfMaskAlpha2;
        private MaterialProperty _useMsdfMaskMain2;
        private MaterialProperty _useMsdfMaskMain3;
        private MaterialProperty _useMsdfMaskShadow;
        private MaterialProperty _useMsdfMaskEmission1;
        private MaterialProperty _useMsdfMaskEmission2;
        private MaterialProperty _useMsdfMaskMatCap1;
        private MaterialProperty _useMsdfMaskMatCap2;

        private string _modeLabelAlpha1 = "";
        private string _modeLabelAlpha2 = "";
        private string _modeLabelMain2 = "";
        private string _modeLabelMain3 = "";
        private string _modeLabelShadow = "";
        private string _modeLabelEmission1 = "";
        private string _modeLabelEmission2 = "";
        private string _modeLabelMatCap1 = "";
        private string _modeLabelMatCap2 = "";

        private static bool isShowAlphaMask2;
        private static bool isShowMsdfMask;
        private const string shaderName = "MsdfMask";

        protected override void LoadCustomProperties(MaterialProperty[] props, Material material)
        {
            isCustomShader = true;

            ReplaceToCustomShaders();
            isShowRenderMode = !material.shader.name.Contains("Optional");

            // strings.tsv GUID
            LoadCustomLanguage("439b5d4be644f894ab70b8d5f47d612e");
            _modeLabelAlpha1 = BuildParams(GetLoc("sAlphaMask"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelAlpha2 = BuildParams(GetLoc("scMMAlphaMask2nd"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelMain2 = BuildParams(GetLoc("sMainColor2nd"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelMain3 = BuildParams(GetLoc("sMainColor3rd"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelShadow = BuildParams(GetLoc("sShadow"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelEmission1 = BuildParams(GetLoc("sEmission"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelEmission2 = BuildParams(GetLoc("sEmission2nd"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelMatCap1 = BuildParams(GetLoc("sMatCap"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));
            _modeLabelMatCap2 = BuildParams(GetLoc("sMatCap2nd"), GetLoc("scMMModeDisabled"), GetLoc("scMMModeEnabled"), GetLoc("scMMModeInverted"));

            _alpha2Mode = FindProperty("_CustomAlphaMask2ndMode", props);
            _alpha2Mask = FindProperty("_CustomAlphaMask2nd", props);
            _alpha2Scale = FindProperty("_CustomAlphaMask2ndScale", props);
            _alpha2Value = FindProperty("_CustomAlphaMask2ndValue", props);
            _useMsdfMaskAlpha1 = FindProperty("_CustomUseMsdfMaskAlpha", props);
            _useMsdfMaskAlpha2 = FindProperty("_CustomUseMsdfMaskAlpha2", props);
            _useMsdfMaskMain2 = FindProperty("_CustomUseMsdfMaskMain2", props);
            _useMsdfMaskMain3 = FindProperty("_CustomUseMsdfMaskMain3", props);
            _useMsdfMaskShadow = FindProperty("_CustomUseMsdfMaskShadow", props);
            _useMsdfMaskEmission1 = FindProperty("_CustomUseMsdfMaskEmission1", props);
            _useMsdfMaskEmission2 = FindProperty("_CustomUseMsdfMaskEmission2", props);
            _useMsdfMaskMatCap1 = FindProperty("_CustomUseMsdfMaskMatCap1", props);
            _useMsdfMaskMatCap2 = FindProperty("_CustomUseMsdfMaskMatCap2", props);
        }

        protected override void DrawCustomProperties(Material material)
        {
            // GUIStyles Name   Description
            // ---------------- ------------------------------------
            // boxOuter         outer box
            // boxInnerHalf     inner box
            // boxInner         inner box without label
            // customBox        box (similar to unity default box)
            // customToggleFont label for box

            isShowAlphaMask2 = Foldout(GetLoc("scMMAlphaMask2nd"), GetLoc("scMMAlphaMask2nd"), isShowAlphaMask2);
            if(isShowAlphaMask2)
            {
                EditorGUILayout.BeginVertical(boxOuter);
                EditorGUILayout.LabelField(GetLoc("scMMAlphaMask2nd"), customToggleFont);
                EditorGUILayout.BeginVertical(boxInnerHalf);

                lilEditorGUI.LocalizedProperty(m_MaterialEditor, _alpha2Mode, false);
                if (_alpha2Mode.floatValue != 0.0f)
                {
                    lilEditorGUI.LocalizedPropertyTexture(m_MaterialEditor, lilLanguageManager.alphaMaskContent, _alpha2Mask, false);
                    lilEditorGUI.UVSettingGUI(m_MaterialEditor, _alpha2Mask);
                    
                    bool invertAlphaMask = _alpha2Scale.floatValue < 0;
                    float transparency = _alpha2Value.floatValue - (invertAlphaMask ? 1.0f : 0.0f);

                    EditorGUI.BeginChangeCheck();
                    EditorGUI.showMixedValue = _alpha2Scale.hasMixedValue || _alpha2Value.hasMixedValue;
                    invertAlphaMask = lilEditorGUI.Toggle("Invert", invertAlphaMask);
                    transparency = lilEditorGUI.Slider("Transparency", transparency, -1.0f, 1.0f);
                    EditorGUI.showMixedValue = false;

                    if(EditorGUI.EndChangeCheck())
                    {
                        _alpha2Scale.floatValue = invertAlphaMask ? -1.0f : 1.0f;
                        _alpha2Value.floatValue = transparency + (invertAlphaMask ? 1.0f : 0.0f);
                    }
                }

                EditorGUILayout.EndVertical();
                EditorGUILayout.EndVertical();
            }

            isShowMsdfMask = Foldout(GetLoc("scMMMSDFMask"), GetLoc("scMMMSDFMask"), isShowMsdfMask);
            if(isShowMsdfMask)
            {
                EditorGUILayout.BeginVertical(boxOuter);
                EditorGUILayout.LabelField(GetLoc("scMMDescription"), customToggleFont);
                EditorGUILayout.BeginVertical(boxInnerHalf);

                m_MaterialEditor.ShaderProperty(_useMsdfMaskAlpha1, _modeLabelAlpha1);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskAlpha2, _modeLabelAlpha2);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskMain2, _modeLabelMain2);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskMain3, _modeLabelMain3);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskShadow, _modeLabelShadow);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskEmission1, _modeLabelEmission1);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskEmission2, _modeLabelEmission2);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskMatCap1, _modeLabelMatCap1);
                m_MaterialEditor.ShaderProperty(_useMsdfMaskMatCap2, _modeLabelMatCap2);

                EditorGUILayout.EndVertical();
                EditorGUILayout.EndVertical();
            }
        }

        protected override void ReplaceToCustomShaders()
        {
            lts         = Shader.Find(shaderName + "/lilToon");
            ltsc        = Shader.Find("Hidden/" + shaderName + "/Cutout");
            ltst        = Shader.Find("Hidden/" + shaderName + "/Transparent");
            ltsot       = Shader.Find("Hidden/" + shaderName + "/OnePassTransparent");
            ltstt       = Shader.Find("Hidden/" + shaderName + "/TwoPassTransparent");

            ltso        = Shader.Find("Hidden/" + shaderName + "/OpaqueOutline");
            ltsco       = Shader.Find("Hidden/" + shaderName + "/CutoutOutline");
            ltsto       = Shader.Find("Hidden/" + shaderName + "/TransparentOutline");
            ltsoto      = Shader.Find("Hidden/" + shaderName + "/OnePassTransparentOutline");
            ltstto      = Shader.Find("Hidden/" + shaderName + "/TwoPassTransparentOutline");

            ltsoo       = Shader.Find(shaderName + "/[Optional] OutlineOnly/Opaque");
            ltscoo      = Shader.Find(shaderName + "/[Optional] OutlineOnly/Cutout");
            ltstoo      = Shader.Find(shaderName + "/[Optional] OutlineOnly/Transparent");

            ltstess     = Shader.Find("Hidden/" + shaderName + "/Tessellation/Opaque");
            ltstessc    = Shader.Find("Hidden/" + shaderName + "/Tessellation/Cutout");
            ltstesst    = Shader.Find("Hidden/" + shaderName + "/Tessellation/Transparent");
            ltstessot   = Shader.Find("Hidden/" + shaderName + "/Tessellation/OnePassTransparent");
            ltstesstt   = Shader.Find("Hidden/" + shaderName + "/Tessellation/TwoPassTransparent");

            ltstesso    = Shader.Find("Hidden/" + shaderName + "/Tessellation/OpaqueOutline");
            ltstessco   = Shader.Find("Hidden/" + shaderName + "/Tessellation/CutoutOutline");
            ltstessto   = Shader.Find("Hidden/" + shaderName + "/Tessellation/TransparentOutline");
            ltstessoto  = Shader.Find("Hidden/" + shaderName + "/Tessellation/OnePassTransparentOutline");
            ltstesstto  = Shader.Find("Hidden/" + shaderName + "/Tessellation/TwoPassTransparentOutline");

            ltsref      = Shader.Find("Hidden/" + shaderName + "/Refraction");
            ltsrefb     = Shader.Find("Hidden/" + shaderName + "/RefractionBlur");
            ltsfur      = Shader.Find("Hidden/" + shaderName + "/Fur");
            ltsfurc     = Shader.Find("Hidden/" + shaderName + "/FurCutout");
            ltsfurtwo   = Shader.Find("Hidden/" + shaderName + "/FurTwoPass");
            ltsfuro     = Shader.Find(shaderName + "/[Optional] FurOnly/Transparent");
            ltsfuroc    = Shader.Find(shaderName + "/[Optional] FurOnly/Cutout");
            ltsfurotwo  = Shader.Find(shaderName + "/[Optional] FurOnly/TwoPass");
            ltsgem      = Shader.Find("Hidden/" + shaderName + "/Gem");
            ltsfs       = Shader.Find(shaderName + "/[Optional] FakeShadow");

            ltsover     = Shader.Find(shaderName + "/[Optional] Overlay");
            ltsoover    = Shader.Find(shaderName + "/[Optional] OverlayOnePass");
            ltslover    = Shader.Find(shaderName + "/[Optional] LiteOverlay");
            ltsloover   = Shader.Find(shaderName + "/[Optional] LiteOverlayOnePass");

            /*
            ltsl        = Shader.Find(shaderName + "/lilToonLite");
            ltslc       = Shader.Find("Hidden/" + shaderName + "/Lite/Cutout");
            ltslt       = Shader.Find("Hidden/" + shaderName + "/Lite/Transparent");
            ltslot      = Shader.Find("Hidden/" + shaderName + "/Lite/OnePassTransparent");
            ltsltt      = Shader.Find("Hidden/" + shaderName + "/Lite/TwoPassTransparent");

            ltslo       = Shader.Find("Hidden/" + shaderName + "/Lite/OpaqueOutline");
            ltslco      = Shader.Find("Hidden/" + shaderName + "/Lite/CutoutOutline");
            ltslto      = Shader.Find("Hidden/" + shaderName + "/Lite/TransparentOutline");
            ltsloto     = Shader.Find("Hidden/" + shaderName + "/Lite/OnePassTransparentOutline");
            ltsltto     = Shader.Find("Hidden/" + shaderName + "/Lite/TwoPassTransparentOutline");
            */

            /*
            ltsm        = Shader.Find(shaderName + "/lilToonMulti");
            ltsmo       = Shader.Find("Hidden/" + shaderName + "/MultiOutline");
            ltsmref     = Shader.Find("Hidden/" + shaderName + "/MultiRefraction");
            ltsmfur     = Shader.Find("Hidden/" + shaderName + "/MultiFur");
            ltsmgem     = Shader.Find("Hidden/" + shaderName + "/MultiGem");
            */
        }
    }
}
#endif
