WITH sales_data AS (
    SELECT
        i.i_brand_id,
        i.i_item_id,
        p.p_promo_name,
        MIN(p.p_channel_details) AS channel_details,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_units LIKE '%Box%'
      AND regexp_like(p.p_channel_details, '(?i)force')
    GROUP BY i.i_brand_id, i.i_item_id, p.p_promo_name
),
returns_data AS (
    SELECT
        i.i_brand_id,
        i.i_item_id,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_units LIKE '%Box%'
    GROUP BY i.i_brand_id, i.i_item_id
)
SELECT
    s.i_brand_id,
    s.i_item_id,
    s.p_promo_name,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_contribution,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    CONCAT(s.p_promo_name, ': ', SUBSTRING(s.channel_details, 1, 30)) AS promo_snippet,
    regexp_extract(s.channel_details, '(?i)force\w*', 1) AS force_word
FROM sales_data s
LEFT JOIN returns_data r
    ON s.i_brand_id = r.i_brand_id
   AND s.i_item_id = r.i_item_id
ORDER BY net_contribution DESC
LIMIT 100
