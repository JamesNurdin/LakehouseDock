WITH overall_avg AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    SUBSTRING(w.w_city, 1, 3) AS city_prefix,
    oa.avg_profit,
    CASE WHEN SUM(cs.cs_net_profit) > oa.avg_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN overall_avg oa ON 1 = 1
WHERE regexp_like(p.p_channel_details, '\\bhigh\\w*\\b')
  AND p.p_purpose LIKE '%Unknown%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_item_sk = cs.cs_item_sk
          AND r.r_reason_desc LIKE '%damage%'
    )
  AND w.w_country = 'United States'
GROUP BY w.w_warehouse_name, p.p_promo_name, w.w_city, oa.avg_profit
ORDER BY total_profit DESC
LIMIT 100
