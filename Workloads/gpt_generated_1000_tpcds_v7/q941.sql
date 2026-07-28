WITH sales_promo AS (
  SELECT
    ws.ws_net_profit,
    w.w_warehouse_name,
    d.d_year,
    d.d_moy,
    ca.ca_city,
    regexp_extract(p.p_promo_id, '(\\d+)', 1) AS promo_code
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca
    ON ws.ws_ship_addr_sk = ca.ca_address_sk
  WHERE regexp_like(p.p_promo_name, 'Discount')
    AND w.w_warehouse_name LIKE '%Warehouse%'
)
SELECT
  w_warehouse_name,
  d_year,
  d_moy,
  promo_code,
  SUM(ws_net_profit) AS total_net_profit,
  COUNT(*) AS order_count,
  SUM(CASE WHEN ca_city LIKE 'A%' THEN ws_net_profit ELSE 0 END) AS profit_city_start_A,
  COUNT(CASE WHEN ca_city LIKE 'A%' THEN 1 END) AS orders_city_start_A
FROM sales_promo
GROUP BY w_warehouse_name, d_year, d_moy, promo_code
ORDER BY total_net_profit DESC
LIMIT 20
