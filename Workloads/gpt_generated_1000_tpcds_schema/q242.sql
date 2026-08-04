WITH
  promo_wh_sales AS (
    SELECT
      p.p_promo_sk,
      w.w_warehouse_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY p.p_promo_sk, w.w_warehouse_sk
  ),
  common_promos AS (
    SELECT p.p_promo_sk
    FROM promotion p
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
    INTERSECT
    SELECT p.p_promo_sk
    FROM promotion p
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 2000
  )
SELECT
  ss.ss_sold_date_sk,
  td_ss.t_hour,
  p_ss.p_promo_id,
  w_cs.w_warehouse_name AS catalog_warehouse,
  w_ws.w_warehouse_name AS web_warehouse,
  cs.cs_ext_sales_price,
  ws.ws_ext_sales_price AS web_sales_price,
  inv.inv_quantity_on_hand,
  ROW_NUMBER() OVER (PARTITION BY p_ss.p_promo_id ORDER BY cs.cs_net_paid DESC) AS promo_rank,
  pw.total_sales,
  l_disc.total_discount
FROM store_sales ss
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN common_promos cp ON p_ss.p_promo_sk = cp.p_promo_sk
LEFT JOIN LATERAL (
  SELECT SUM(cs3.cs_ext_discount_amt) AS total_discount
  FROM catalog_sales cs3
  WHERE cs3.cs_promo_sk = p_ss.p_promo_sk
) AS l_disc ON TRUE
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN catalog_sales cs ON cs.cs_promo_sk = p_ss.p_promo_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN web_sales ws ON ws.ws_promo_sk = p_ss.p_promo_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN promo_wh_sales pw ON pw.p_promo_sk = p_ss.p_promo_sk
  AND pw.w_warehouse_sk = w_cs.w_warehouse_sk
LIMIT 100
