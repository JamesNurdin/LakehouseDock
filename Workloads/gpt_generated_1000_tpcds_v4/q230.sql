WITH sales_agg AS (
   SELECT
       w.w_warehouse_sk,
       w.w_warehouse_id,
       w.w_warehouse_name,
       p.p_promo_sk,
       p.p_promo_name,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       AVG(cs.cs_quantity) AS avg_quantity
   FROM catalog_sales cs
   JOIN customer_demographics cd
       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
   JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE p.p_channel_event = 'Y'
     AND p.p_discount_active = 'Y'
     AND w.w_state = 'CA'
     AND cd.cd_gender = 'M'
     AND cd.cd_dep_employed_count >= 2
     AND cs.cs_quantity > 1
   GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name,
            p.p_promo_sk, p.p_promo_name
),

promo_stats AS (
   SELECT
       p.p_promo_sk,
       MAX(p.p_cost) AS max_cost,
       AVG(p.p_cost) AS avg_cost
   FROM promotion p
   WHERE p.p_discount_active = 'Y'
   GROUP BY p.p_promo_sk
),

final_agg AS (
   SELECT
       s.w_warehouse_id,
       s.w_warehouse_name,
       s.p_promo_name,
       s.total_net_profit,
       s.distinct_orders,
       s.avg_quantity,
       ps.max_cost,
       ps.avg_cost,
       ROW_NUMBER() OVER (PARTITION BY s.w_warehouse_id ORDER BY s.total_net_profit DESC) AS rn,
       (SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = s.w_warehouse_sk
          AND cs2.cs_promo_sk = s.p_promo_sk) AS warehouse_promo_sales_cnt
   FROM sales_agg s
   JOIN promo_stats ps
       ON s.p_promo_sk = ps.p_promo_sk
   WHERE ps.max_cost > 50
)

SELECT
   w_warehouse_id,
   w_warehouse_name,
   p_promo_name,
   total_net_profit,
   distinct_orders,
   avg_quantity,
   max_cost,
   avg_cost,
   warehouse_promo_sales_cnt
FROM final_agg
WHERE rn = 1
ORDER BY total_net_profit DESC
LIMIT 100
