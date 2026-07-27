WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_promo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_cnt,
        MIN(cs_sales_price) AS min_price,
        MAX(cs_sales_price) AS max_price
    FROM catalog_sales
    WHERE cs_sales_price > 20.00               -- filter 1 (price)
      AND cs_quantity >= 2                     -- filter 2 (quantity)
      AND cs_ext_tax < 5.00                    -- filter 3 (tax amount)
    GROUP BY cs_call_center_sk, cs_promo_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    p.p_promo_id,
    p.p_promo_name,
    sa.total_sales,
    sa.avg_discount,
    sa.order_cnt,
    sa.min_price,
    sa.max_price,
    (
        SELECT MAX(total_sales)
        FROM sales_agg sa2
        WHERE sa2.cs_promo_sk = sa.cs_promo_sk
    ) AS max_total_sales_for_promo,                     -- scalar subquery
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY sa.total_sales DESC) AS division_sales_rank   -- window function
FROM sales_agg sa
JOIN call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
WHERE cc.cc_state = 'CA'                         -- filter on call center state
  AND p.p_purpose = 'Unknown'                    -- filter on promotion purpose
  AND p.p_channel_event = 'N'                    -- filter on promotion channel flag
ORDER BY cc.cc_division, division_sales_rank
