WITH billed AS (
   SELECT
       cs.cs_bill_hdemo_sk AS hd_demo_sk,
       cs.cs_order_number,
       cs.cs_ext_ship_cost,
       cs.cs_coupon_amt,
       cs.cs_net_profit,
       hd.hd_vehicle_count,
       hd.hd_dep_count,
       CASE WHEN cs.cs_coupon_amt > 200 THEN 'HIGH_COUPON' ELSE 'LOW_COUPON' END AS coupon_category
   FROM catalog_sales cs
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_ext_ship_cost > 500
     AND cs.cs_coupon_amt > 100
     AND hd.hd_vehicle_count >= 1
),
shipped AS (
   SELECT
       cs.cs_ship_hdemo_sk AS hd_demo_sk,
       cs.cs_order_number,
       cs.cs_ext_ship_cost,
       cs.cs_coupon_amt,
       cs.cs_net_profit,
       hd.hd_vehicle_count,
       hd.hd_dep_count,
       CASE WHEN cs.cs_coupon_amt > 200 THEN 'HIGH_COUPON' ELSE 'LOW_COUPON' END AS coupon_category
   FROM catalog_sales cs
   JOIN household_demographics hd
     ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   WHERE cs.cs_ext_ship_cost > 500
     AND cs.cs_coupon_amt > 100
     AND hd.hd_vehicle_count >= 1
),
combined_demo AS (
   SELECT DISTINCT hd_demo_sk FROM billed
   UNION
   SELECT DISTINCT hd_demo_sk FROM shipped
),
unified AS (
   SELECT * FROM billed
   UNION ALL
   SELECT * FROM shipped
),
ranked AS (
   SELECT
       u.hd_demo_sk,
       u.cs_order_number,
       u.cs_net_profit,
       u.coupon_category,
       ROW_NUMBER() OVER (PARTITION BY u.hd_demo_sk ORDER BY u.cs_net_profit DESC) AS profit_rank,
       AVG(u.cs_net_profit) OVER (PARTITION BY u.hd_demo_sk) AS avg_profit_hd
   FROM unified u
   JOIN combined_demo cd ON u.hd_demo_sk = cd.hd_demo_sk
   WHERE u.cs_net_profit IS NOT NULL
),
avg_discount AS (
   SELECT AVG(cs_ext_discount_amt) AS overall_avg_discount
   FROM catalog_sales
   WHERE cs_ext_discount_amt IS NOT NULL
)
SELECT
   r.hd_demo_sk,
   r.cs_order_number,
   r.cs_net_profit,
   r.coupon_category,
   r.profit_rank,
   CASE WHEN r.cs_net_profit > ad.overall_avg_discount * 10 THEN 'ABOVE_THRESHOLD' ELSE 'NORMAL' END AS profit_flag
FROM ranked r
CROSS JOIN avg_discount ad
WHERE r.profit_rank <= 5
ORDER BY r.hd_demo_sk, r.profit_rank
