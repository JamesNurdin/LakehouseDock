WITH sales_agg AS (
   SELECT
      cs_ship_mode_sk,
      cs_promo_sk,
      COUNT(*) AS order_cnt,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit,
      AVG(cs_wholesale_cost) AS avg_wholesale,
      SUM(cs_quantity) AS total_qty
   FROM catalog_sales
   WHERE cs_promo_sk IN (380, 1023, 1057)
     AND cs_wholesale_cost > 50
   GROUP BY cs_ship_mode_sk, cs_promo_sk
),
joined AS (
   SELECT
      sm.sm_carrier,
      sm.sm_type,
      sa.cs_promo_sk,
      sa.order_cnt,
      sa.total_sales,
      sa.total_profit,
      sa.avg_wholesale,
      sa.total_qty
   FROM sales_agg sa
   JOIN ship_mode sm
     ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_carrier IN ('DHL', 'BOXBUNDLES', 'RUPEKSA')
)
SELECT
   sm_carrier,
   sm_type,
   cs_promo_sk,
   SUM(order_cnt)               AS sum_order_cnt,
   SUM(total_sales)             AS sum_total_sales,
   SUM(total_profit)            AS sum_total_profit,
   AVG(avg_wholesale)           AS avg_wholesale,
   SUM(total_qty)               AS sum_total_qty,
   ROW_NUMBER() OVER (
      PARTITION BY sm_carrier
      ORDER BY SUM(total_sales) DESC
   )                              AS carrier_rank,
   CASE WHEN SUM(total_profit) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE_OR_ZERO' END AS profit_indicator
FROM joined
GROUP BY ROLLUP (sm_carrier, sm_type, cs_promo_sk)
ORDER BY sm_carrier NULLS LAST,
         sm_type NULLS LAST,
         cs_promo_sk NULLS LAST
LIMIT 100
