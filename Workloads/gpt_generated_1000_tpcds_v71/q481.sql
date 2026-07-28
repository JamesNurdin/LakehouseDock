WITH agg_sales AS (
    SELECT
        cs_call_center_sk,
        cs_promo_sk,
        COUNT(*) AS order_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_list_price) AS avg_list_price,
        MIN(cs_list_price) AS min_list_price,
        MAX(cs_list_price) AS max_list_price
    FROM catalog_sales
    WHERE cs_list_price >= 90.00                     -- filter 1
      AND cs_quantity BETWEEN 1 AND 5                -- filter 2
      AND cs_ship_customer_sk IN (4482187, 3897282, 5799445)  -- filter 3
    GROUP BY cs_call_center_sk, cs_promo_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    p.p_promo_name,
    p.p_discount_active,
    agg.order_cnt,
    agg.total_sales,
    agg.avg_list_price,
    agg.min_list_price,
    agg.max_list_price,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY agg.total_sales DESC) AS rn_state
FROM agg_sales agg
JOIN call_center cc
  ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
  ON agg.cs_promo_sk = p.p_promo_sk
WHERE cc.cc_tax_percentage <= 0.08                -- filter 4
  AND cc.cc_street_type = 'Road'                    -- filter 5
  AND cc.cc_state IN ('CA', 'TX', 'NY')             -- filter 6
  AND p.p_channel_tv = 'Y'                          -- filter 7
  AND p.p_promo_name LIKE '%Summer%'                -- filter 8
  AND p.p_cost < 5000                               -- filter 9
ORDER BY agg.total_sales DESC
LIMIT 100
