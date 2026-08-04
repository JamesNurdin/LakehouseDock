/*
  Goal: Analyze net profit performance by profit category and call‑center, using a deep join of all five TPC‑DS tables (with multiple aliases), sample the call_center table, intersect two filtered key sets, apply a CASE expression, filter with an anti‑join, aggregate with ROLLUP for subtotals and a grand total, and order the final result.
*/
WITH sampled_cc AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of call_center rows
),
order_intersect AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN sampled_cc cc_main ON cs.cs_call_center_sk = cc_main.cc_call_center_sk
    WHERE cc_main.cc_state = 'CA'
    INTERSECT
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_purpose = 'Unknown'
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cc_main.cc_name,
        cd_bill.cd_gender               AS bill_gender,
        cd_ship.cd_gender               AS ship_gender,
        p1.p_promo_name,
        p2.p_cost                       AS promo_cost_alt,
        sm1.sm_type                     AS ship_type,
        sm2.sm_type                     AS ship_type_alt,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    -- first join to the sampled call_center (alias cc_main)
    JOIN sampled_cc cc_main ON cs.cs_call_center_sk = cc_main.cc_call_center_sk
    -- two different roles for customer_demographics
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    -- two different aliases for promotion
    JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
    JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
    -- two different aliases for ship_mode
    JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2 ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    -- a second alias for call_center (different role)
    JOIN call_center cc_alt ON cs.cs_call_center_sk = cc_alt.cc_call_center_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_intersect)
      AND NOT EXISTS (
            SELECT 1
            FROM promotion p_check
            WHERE p_check.p_promo_sk = cs.cs_promo_sk
              AND p_check.p_discount_active = 'Y'
          )
)
SELECT
    profit_category,
    cc_name,
    COUNT(DISTINCT cs_order_number)               AS orders_cnt,
    SUM(cs_net_profit)                           AS total_profit,
    SUM(cs_net_profit) / NULLIF(COUNT(DISTINCT cs_order_number), 0) AS avg_profit_per_order
FROM joined_data
GROUP BY ROLLUP (profit_category, cc_name)
HAVING COUNT(*) > 5
ORDER BY profit_category ASC, cc_name ASC NULLS LAST
