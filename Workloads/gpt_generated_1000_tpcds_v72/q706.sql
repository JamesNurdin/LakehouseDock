WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_formulation, '[a-z]{3}[0-9]{4}')
      AND i.i_current_price > 20
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
)
SELECT DISTINCT
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    CASE
        WHEN i.i_brand = 'BrandX' THEN 'Premium'
        WHEN i.i_brand = 'BrandY' THEN 'Standard'
        ELSE 'Other'
    END AS brand_category,
    regexp_extract(i.i_formulation, '([0-9]{4})', 1) AS formulation_code,
    sa.total_net_profit,
    sa.sales_cnt,
    (SELECT AVG(total_net_profit) FROM sales_agg) AS avg_store_item_profit,
    CASE
        WHEN sa.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_flag
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
WHERE s.s_street_type LIKE '%Drive%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = i.i_item_sk
          AND sr.sr_store_sk = s.s_store_sk
          AND sr.sr_return_quantity > 0
    )
ORDER BY sa.total_net_profit DESC
LIMIT 100
