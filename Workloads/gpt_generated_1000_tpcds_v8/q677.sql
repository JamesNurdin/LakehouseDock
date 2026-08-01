WITH
cs_join AS (
   SELECT
     cs.cs_order_number,
     cs.cs_net_paid,
     ca.ca_state AS cs_state,
     sm.sm_type AS cs_ship_type,
     w.w_warehouse_name AS cs_warehouse_name,
     p.p_promo_name AS cs_promo_name,
     t.t_hour AS cs_hour,
     cs.cs_promo_sk
   FROM catalog_sales cs
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE ca.ca_state = 'CA'
     AND sm.sm_type = 'EXPRESS'
     AND p.p_channel_event = 'N'
     AND t.t_hour BETWEEN 9 AND 17
     AND cs.cs_net_paid > 500
     AND w.w_city = 'Los Angeles'
),
ws_join AS (
   SELECT
     ws.ws_order_number,
     ws.ws_net_paid,
     ca2.ca_state AS ws_state,
     sm2.sm_type AS ws_ship_type,
     w2.w_warehouse_name AS ws_warehouse_name,
     p2.p_promo_name AS ws_promo_name,
     t2.t_hour AS ws_hour,
     ws.ws_promo_sk
   FROM web_sales ws
   JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
   JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
   JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
   JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
   WHERE ca2.ca_state = 'TX'
     AND sm2.sm_type = 'OVERNIGHT'
     AND p2.p_channel_event = 'N'
     AND t2.t_hour BETWEEN 8 AND 18
     AND ws.ws_net_paid > 400
     AND w2.w_city = 'Houston'
),
intersect_orders AS (
   SELECT cs_order_number FROM cs_join
   INTERSECT
   SELECT ws_order_number FROM ws_join
),
full_combined AS (
   SELECT
     COALESCE(cs.cs_order_number, ws.ws_order_number) AS order_number,
     cs.cs_net_paid,
     ws.ws_net_paid,
     cs.cs_state,
     ws.ws_state,
     cs.cs_ship_type,
     ws.ws_ship_type,
     cs.cs_promo_name,
     ws.ws_promo_name,
     cs.cs_hour,
     ws.ws_hour,
     cs.cs_promo_sk
   FROM cs_join cs
   FULL OUTER JOIN ws_join ws
     ON cs.cs_order_number = ws.ws_order_number
   WHERE COALESCE(cs.cs_order_number, ws.ws_order_number) IN (SELECT cs_order_number FROM intersect_orders)
),
filtered AS (
   SELECT *
   FROM full_combined fc
   WHERE NOT EXISTS (
     SELECT 1
     FROM promotion p
     WHERE p.p_promo_sk = fc.cs_promo_sk
       AND p.p_channel_email = 'Y'
   )
),
union_agg AS (
   SELECT state, total_paid FROM (
       SELECT cs_state AS state, SUM(cs_net_paid) AS total_paid
       FROM filtered
       WHERE cs_net_paid IS NOT NULL
       GROUP BY cs_state
   )
   UNION
   SELECT state, total_paid FROM (
       SELECT ws_state AS state, SUM(ws_net_paid) AS total_paid
       FROM filtered
       WHERE ws_net_paid IS NOT NULL
       GROUP BY ws_state
   )
),
final AS (
   SELECT
     u.state,
     u.total_paid,
     COUNT(DISTINCT u.state) OVER () AS distinct_state_cnt,
     ROW_NUMBER() OVER (ORDER BY u.total_paid DESC) AS rn,
     (
       SELECT MAX(fc.cs_net_paid)
       FROM filtered fc
       WHERE fc.cs_state = u.state
     ) AS max_cs_net_paid
   FROM union_agg u
   WHERE u.state IN (
       SELECT DISTINCT cs_state
       FROM filtered
       WHERE cs_net_paid > 1000
   )
)
SELECT
  state,
  total_paid,
  distinct_state_cnt,
  rn,
  max_cs_net_paid
FROM final
ORDER BY total_paid DESC
LIMIT 100
