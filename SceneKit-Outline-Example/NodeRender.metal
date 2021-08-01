#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct custom_node_t3 {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
};

struct custom_vertex_t
{
    float4 position [[attribute(SCNVertexSemanticPosition)]];
    float4 normal [[attribute(SCNVertexSemanticNormal)]];
};

struct out_vertex_t
{
    float4 position [[position]];
    float2 uv;
};

typedef struct {
    float3 outlineColor;
} Inputs;

typedef struct {
    float3 outlineWidth;
} VertInputs;

vertex out_vertex_t mask_vertex(custom_vertex_t in [[stage_in]],
                                constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                constant custom_node_t3& scn_node [[buffer(1)]],
                                constant VertInputs& inputs [[buffer(2)]]

                                )
{
    out_vertex_t out;
    
    //we need the MVP matrices without position offset. just for rotating the normals to clip space
    //TODO: ugly way to initialize float3x3. maybe something cleaner
    float3x3 VP_M = float3x3({scn_frame.viewProjectionTransform.columns[0][0], scn_frame.viewProjectionTransform.columns[0][1], scn_frame.viewProjectionTransform.columns[0][2]}, {scn_frame.viewProjectionTransform.columns[1][0], scn_frame.viewProjectionTransform.columns[1][1], scn_frame.viewProjectionTransform.columns[1][2]}, {scn_frame.viewProjectionTransform.columns[2][0], scn_frame.viewProjectionTransform.columns[2][1], scn_frame.viewProjectionTransform.columns[2][2]});
    
    float3x3 M_M = float3x3({scn_node.modelTransform.columns[0][0], scn_node.modelTransform.columns[0][1], scn_node.modelTransform.columns[0][2]}, {scn_node.modelTransform.columns[1][0], scn_node.modelTransform.columns[1][1], scn_node.modelTransform.columns[1][2]}, {scn_node.modelTransform.columns[2][0], scn_node.modelTransform.columns[2][1], scn_node.modelTransform.columns[2][2]});
   
    //transform the normal direction into clip space by multiplying by the rotational components of the
    //view projection matrix and model matrix
    float3 clipNormal = VP_M * M_M * in.normal.xyz;
    
    //get vertex input position in clip space
    float4 clipPos = scn_node.modelViewProjectionTransform * in.position;
    
    //read in the viewport size
    float2 vpSize = scn_frame.viewportSize.xy;
    
    
    //offset the normal in view space. divide offset to make line thickness in screen pixels. multiply by w component to undo perspective division in rasterization step after vertex and before fragment
    float2 offset = normalize(clipNormal.xy) / vpSize * inputs.outlineWidth.x * clipPos.w;
    
    //add outline offset to screen position of vertex
    clipPos.xy += offset;
    out.position = clipPos;
    return out;
};

fragment half4 mask_fragment(out_vertex_t in [[stage_in]],
                                          texture2d<float, access::sample> colorSampler [[texture(0)]])
{
    //draw the mask as full white pixels
    return half4(1);
};

constexpr sampler s = sampler(coord::normalized,
                              r_address::clamp_to_edge,
                              t_address::repeat,
                              filter::linear);

//full screen quad vertex shader
vertex out_vertex_t combine_vertex(custom_vertex_t in [[stage_in]])
{
    out_vertex_t out;
    out.position = in.position;
    out.uv = float2( (in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5 );
    return out;
};

fragment half4 combine_fragment(out_vertex_t vert [[stage_in]],
                                texture2d<float, access::sample> colorSampler [[texture(0)]],
                                texture2d<float, access::sample> maskSampler [[texture(1)]],
                                constant Inputs& inputs [[buffer(0)]])
{
    
    float4 FragmentColor = colorSampler.sample( s, vert.uv);
    float4 maskColor = maskSampler.sample(s, vert.uv);
    float3 outlineColor = inputs.outlineColor;
    
    float alpha = FragmentColor.a;
    //draw the full render pass on top of mask pass using the alpha channel.
    //multiply the mask by the outline color
    float3 out = mix(FragmentColor.rgb,maskColor.rgb * outlineColor,1-alpha);
    
    return half4( float4(out.rgb, 1) );
    
}

