WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),

joined AS (
   SELECT
      ss.cs_ship_date_sk,
      ss.cs_net_paid_inc_tax,
      ss.cs_coupon_amt,
      ss.cs_quantity,
      ss.cs_wholesale_cost,
      ss.cs_ext_sales_price,
      ss.cs_ext_discount_amt,
      ss.cs_ship_mode_sk,
      ss.cs_warehouse_sk,
      sm.sm_carrier,
      sm.sm_type,
      wh.w_state,
      wh.w_city
   FROM sampled_sales ss
   JOIN ship_mode sm
     ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse wh
     ON ss.cs_warehouse_sk = wh.w_warehouse_sk
   WHERE ss.cs_ship_date_sk BETWEEN 2450820 AND 2450890               -- realistic ship date range
     AND ss.cs_net_paid_inc_tax > 400.00                              -- filter high‑value sales
     AND sm.sm_carrier = 'USPS'                                       -- focus on a carrier
),

aggregated AS (
   SELECT
      sm_carrier,
      w_state,
      COUNT(*) AS order_cnt,
      SUM(cs_ext_sales_price) AS total_sales,
      AVG(cs_ext_discount_amt) AS avg_discount,
      MIN(cs_coupon_amt) AS min_coupon,
      MAX(cs_coupon_amt) AS max_coupon,
      CASE
         WHEN SUM(cs_ext_sales_price) > 50000 THEN 'High'
         ELSE 'Medium'
      END AS sales_category
   FROM joined
   GROUP BY sm_carrier, w_state
),

ranked AS (
   SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY sm_carrier ORDER BY total_sales DESC) AS carrier_rank
   FROM aggregated
   WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_carrier = aggregated.sm_carrier
          AND sm2.sm_type IS NOT NULL
   )
)
SELECT
   sm_carrier,
   w_state,
   order_cnt,
   total_sales,
   avg_discount,
   min_coupon,
   max_coupon,
   sales_category,
   carrier_rank
FROM ranked
WHERE carrier_rank <= 5               -- top‑5 warehouses per carrier
ORDER BY sm_carrier, carrier_rank
LIMIT 100
