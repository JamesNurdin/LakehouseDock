WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        CASE
            WHEN sm.sm_type = 'OVERNIGHT' THEN 'Fast'
            WHEN sm.sm_type = 'TWO DAY' THEN 'Standard'
            ELSE 'Other'
        END AS shipping_category
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_quantity > 10
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450840
      AND cc.cc_state = 'CA'
      AND sm.sm_contract LIKE 'Y%'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_id,
        sm.sm_type,
        CASE
            WHEN sm.sm_type = 'OVERNIGHT' THEN 'Fast'
            WHEN sm.sm_type = 'TWO DAY' THEN 'Standard'
            ELSE 'Other'
        END
)
SELECT
    shipping_category,
    AVG(total_profit) AS avg_profit,
    SUM(total_sales) AS sum_sales,
    COUNT(*) AS num_groups,
    (SELECT MAX(total_sales) FROM sales_agg) AS max_sales_global
FROM sales_agg
WHERE total_sales > 10000
  AND order_cnt >= 5
GROUP BY shipping_category
HAVING AVG(total_profit) > 500
ORDER BY avg_profit DESC
