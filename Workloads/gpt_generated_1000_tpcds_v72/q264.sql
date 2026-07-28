WITH cs_joined AS (
   SELECT
       cs.cs_order_number       AS order_number,
       cs.cs_quantity           AS quantity,
       cs.cs_net_paid           AS net_paid,
       cs.cs_sold_date_sk       AS sold_date_sk,
       ca.ca_state              AS state,
       sm.sm_code               AS ship_mode,
       w.w_warehouse_name       AS w_warehouse_name,
       p.p_promo_name           AS p_promo_name,
       p.p_discount_active     AS p_discount_active,
       p.p_cost                 AS p_cost
   FROM catalog_sales cs
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w        ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p        ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_quantity > 5
     AND sm.sm_code IN ('AIR', 'SEA')
     AND p.p_channel_radio = 'N'
     AND w.w_state = 'CA'
     AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
),
ws_joined AS (
   SELECT
       ws.ws_order_number       AS order_number,
       ws.ws_quantity           AS quantity,
       ws.ws_net_paid           AS net_paid,
       ws.ws_sold_date_sk       AS sold_date_sk,
       ca2.ca_state             AS state,
       sm2.sm_code              AS ship_mode,
       w2.w_warehouse_name      AS w_warehouse_name,
       p2.p_promo_name          AS p_promo_name,
       p2.p_discount_active    AS p_discount_active,
       p2.p_cost                AS p_cost
   FROM web_sales ws
   JOIN customer_address ca2 ON ws.ws_ship_addr_sk = ca2.ca_address_sk
   JOIN ship_mode sm2        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN warehouse w2        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
   JOIN promotion p2        ON ws.ws_promo_sk = p2.p_promo_sk
   WHERE ws.ws_quantity > 5
     AND sm2.sm_code IN ('AIR', 'SEA')
     AND p2.p_channel_radio = 'N'
     AND w2.w_state = 'CA'
     AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
),
combined AS (
   SELECT
       order_number,
       quantity,
       net_paid,
       state,
       ship_mode,
       w_warehouse_name,
       p_promo_name,
       CASE WHEN p_discount_active = 'Y' THEN net_paid * 0.9 ELSE net_paid END AS adjusted_net_paid,
       p_cost
   FROM cs_joined
   UNION ALL
   SELECT
       order_number,
       quantity,
       net_paid,
       state,
       ship_mode,
       w_warehouse_name,
       p_promo_name,
       CASE WHEN p_discount_active = 'Y' THEN net_paid * 0.9 ELSE net_paid END,
       p_cost
   FROM ws_joined
),
aggregated AS (
   SELECT
       w_warehouse_name,
       ship_mode,
       p_promo_name,
       COUNT(*)                              AS orders_cnt,
       SUM(adjusted_net_paid)                AS total_adj_net,
       AVG(adjusted_net_paid)                AS avg_adj_net,
       MAX(p_cost)                           AS max_promo_cost
   FROM combined
   WHERE adjusted_net_paid > (
         SELECT AVG(adjusted_net_paid) FROM combined
       )
   GROUP BY ROLLUP (w_warehouse_name, ship_mode, p_promo_name)
   HAVING COUNT(*) > 10
)
SELECT
   w_warehouse_name,
   ship_mode,
   p_promo_name,
   orders_cnt,
   total_adj_net,
   avg_adj_net,
   max_promo_cost,
   ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_adj_net DESC) AS rn
FROM aggregated
ORDER BY w_warehouse_name, ship_mode, p_promo_name
LIMIT 100
