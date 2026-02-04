import { createClient } from "jsr:@supabase/supabase-js@2";
import OpenAI from "https://deno.land/x/openai@v4.69.0/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const { poiType, dangerLevel, poiName } = await req.json();

    if (!poiType || !dangerLevel) {
      return new Response(
        JSON.stringify({ error: "Missing poiType or dangerLevel" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call Alibaba Cloud DashScope (qwen-flash) via OpenAI-compatible API
    const dashscopeKey = Deno.env.get("DASHSCOPE_API_KEY");
    if (!dashscopeKey) {
      return new Response(
        JSON.stringify({ error: "DASHSCOPE_API_KEY not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const openai = new OpenAI({
      apiKey: dashscopeKey,
      baseURL: "https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
    });

    const systemPrompt = `你是一个末日生存游戏物品生成器。根据传入的 POI 类型和危险等级，生成 1-3 件独特的末日废土风格物品。
规则：
- 危险等级越高，物品越稀有、越有价值
- 每件物品需要有独特的名字和末日风格的背景故事（2-3 句话）
- rarity 从 common/rare/epic/legendary 中选择
- weight 单位为 kg，合理范围 0.01-5.0
- icon 必须是有效的 SF Symbol 名称（如 drop.fill, cross.case.fill, wrench.fill, bolt.fill, shield.fill 等）

严格返回以下 JSON 格式，不要包含其他文字：
{
  "items": [
    {
      "name": "物品中文名",
      "rarity": "rare",
      "backstory": "这件物品的末日背景故事...",
      "weight": 0.5,
      "icon": "cross.case.fill"
    }
  ]
}`;

    const userPrompt = `POI 类型：${poiType}${poiName ? `（${poiName}）` : ""}，危险等级：${dangerLevel}/5。请生成物品。`;

    const completion = await openai.chat.completions.create({
      model: "qwen-plus",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.9,
      max_tokens: 800,
    });

    const content = completion.choices[0]?.message?.content ?? "";

    // Extract JSON from response (handle markdown code blocks)
    let jsonStr = content;
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonStr = jsonMatch[1].trim();
    }

    const parsed = JSON.parse(jsonStr);

    // Tag each item as AI-generated
    const items = (parsed.items || []).map(
      (item: Record<string, unknown>) => ({
        ...item,
        isAIGenerated: true,
      })
    );

    return new Response(JSON.stringify({ items, userId: user.id }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: "AI generation failed",
        details: String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
