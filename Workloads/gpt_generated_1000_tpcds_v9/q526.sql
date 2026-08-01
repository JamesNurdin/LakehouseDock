/* goal: Compute total catalog and store net profit and sales by warehouse city, ship mode, promotion, and hour of day, only for catalog sales that have a matching store sale with the same promotion and hour */
SELECT
  w.w_city AS warehouse_city,
  w.w_state AS warehouse_state,
  sm.sm_type AS ship_mode_type,
  p_cat.p_promo_name AS promo_name,
  td.t_hour AS hour_of_day,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  SUM(cs.cs_net_profit) AS catalog_total_net_profit,
  SUM(cs.cs_ext_sales_price) AS catalog_total_sales,
  COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
  SUM(ss.ss_net_profit) AS store_total_net_profit,
  SUM(ss.ss_ext_sales_price) AS store_total_sales
FROM catalog_sales cs
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p_cat
  ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_address ca_store
  ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN promotion p_store
  ON ss.ss_promo_sk = p_store.p_promo_sk
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss2
  JOIN time_dim td2 ON ss2.ss_sold_time_sk = td2.t_time_sk
  WHERE ss2.ss_promo_sk = cs.cs_promo_sk
    AND td2.t_hour = td.t_hour
)
GROUP BY
  w.w_city,
  w.w_state,
  sm.sm_type,
  p_cat.p_promo_name,
  td.t_hour
ORDER BY
  catalog_total_net_profit DESC,
  warehouse_city
LIMIT 100
