/* goal: Identify the top-performing warehouses per call center, enriched with call‑center and household demographics details, applying multiple business filters and ranking the results */
WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_hdemo_sk,
        SUM(cs.cs_net_profit)               AS total_profit,
        SUM(cs.cs_ext_ship_cost)            AS total_ship_cost,
        COUNT(*)                            AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_ext_discount_amt < 2000
      AND cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_quantity >= 1
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND cs.cs_sold_time_sk IS NOT NULL
    GROUP BY cs.cs_warehouse_sk, cs.cs_call_center_sk, cs.cs_bill_hdemo_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    w.w_warehouse_id,
    w.w_city AS warehouse_city,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    sa.total_profit,
    sa.total_ship_cost,
    sa.order_cnt,
    CASE
        WHEN sa.total_profit > 10000 THEN 'High'
        WHEN sa.total_profit > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY sa.total_profit DESC) AS warehouse_rank,
    (
        SELECT MAX(cs2.cs_ext_ship_cost)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = sa.cs_warehouse_sk
    ) AS max_ship_cost_per_warehouse
FROM sales_agg sa
INNER JOIN call_center cc
        ON sa.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN warehouse w
        ON sa.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN household_demographics hd
        ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND w.w_gmt_offset = -6.00
  AND hd.hd_buy_potential IN ('1001-5000','501-1000')
  AND hd.hd_dep_count BETWEEN 1 AND 5
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_income_band_sk = 3
          AND hd2.hd_demo_sk = sa.cs_bill_hdemo_sk
    )
ORDER BY profit_category, sa.total_profit DESC
LIMIT 100
