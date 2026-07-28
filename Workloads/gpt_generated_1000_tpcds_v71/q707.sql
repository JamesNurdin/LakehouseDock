WITH sales_enriched AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_category,
        i.i_item_desc,
        ss.ss_net_profit,
        p.p_promo_name,
        regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS sku_code,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND (s.s_store_name LIKE '%Market%' OR s.s_store_name LIKE '%Outlet%')
)
SELECT
    s_store_name,
    i_category,
    COUNT(DISTINCT ss_ticket_number) AS order_count,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN profit_flag = 'POSITIVE' THEN ss_net_profit ELSE 0 END) AS positive_profit,
    MAX(sku_code) FILTER (WHERE sku_code IS NOT NULL) AS example_sku,
    COUNT(CASE WHEN regexp_like(p_promo_name, '^Summer.*') THEN 1 END) AS summer_promo_orders,
    MAX(CONCAT(s_store_name, ' - ', i_category)) AS store_category_label
FROM sales_enriched
GROUP BY s_store_name, i_category
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
