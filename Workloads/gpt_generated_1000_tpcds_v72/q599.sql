SELECT
    s.s_store_id,
    d_sales.d_year,
    p.p_promo_name,
    p2.p_promo_name AS cs_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_net_paid * 0.9 ELSE ss.ss_net_paid END) AS adjusted_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    (SELECT MAX(w2.w_warehouse_sq_ft) FROM warehouse w2) AS max_warehouse_sq_ft
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
 AND cs.cs_sold_time_sk = t.t_time_sk
JOIN promotion p2
  ON cs.cs_promo_sk = p2.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
 AND ws.ws_sold_time_sk = t.t_time_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ship_cs
  ON cs.cs_ship_date_sk = d_ship_cs.d_date_sk
WHERE s.s_store_id IN (
    SELECT s2.s_store_id
    FROM store s2
    WHERE s2.s_number_employees > 200
)
GROUP BY
    s.s_store_id,
    d_sales.d_year,
    p.p_promo_name,
    p2.p_promo_name
HAVING SUM(ss.ss_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
