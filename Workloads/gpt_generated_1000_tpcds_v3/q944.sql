WITH cs_agg AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_warehouse_sk,
    cs.cs_promo_sk,
    c_bill.c_customer_id AS bill_customer_id,
    c_ship.c_customer_id AS ship_customer_id,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount
  FROM catalog_sales cs
  JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
  JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
  JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
  JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  GROUP BY
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_warehouse_sk,
    cs.cs_promo_sk,
    c_bill.c_customer_id,
    c_ship.c_customer_id
)
SELECT
  t_ss.t_time AS store_sale_time,
  t_cs2.t_time AS catalog_sale_time,
  c_ss.c_customer_id AS store_customer_id,
  cs_agg.bill_customer_id,
  cs_agg.ship_customer_id,
  w2.w_warehouse_name,
  p_ss.p_promo_name AS store_promo_name,
  p_cs.p_promo_name AS catalog_promo_name,
  SUM(ss.ss_net_profit) AS total_store_net_profit,
  cs_agg.catalog_net_profit,
  SUM(ss.ss_net_profit) + cs_agg.catalog_net_profit AS combined_net_profit,
  (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM store_sales ss
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer c_ss
  ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN promotion p_ss
  ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN cs_agg
  ON cs_agg.cs_promo_sk = p_ss.p_promo_sk
JOIN warehouse w2
  ON cs_agg.cs_warehouse_sk = w2.w_warehouse_sk
JOIN time_dim t_cs2
  ON cs_agg.cs_sold_time_sk = t_cs2.t_time_sk
JOIN promotion p_cs
  ON cs_agg.cs_promo_sk = p_cs.p_promo_sk
GROUP BY
  t_ss.t_time,
  t_cs2.t_time,
  c_ss.c_customer_id,
  cs_agg.bill_customer_id,
  cs_agg.ship_customer_id,
  w2.w_warehouse_name,
  p_ss.p_promo_name,
  p_cs.p_promo_name,
  cs_agg.catalog_net_profit
ORDER BY combined_net_profit DESC
LIMIT 100
