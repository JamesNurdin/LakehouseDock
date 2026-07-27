WITH ss_agg AS (
       SELECT
         ss.ss_customer_sk                         AS cust_sk,
         SUM(ss.ss_net_paid)                      AS total_store_net_paid,
         SUM(ss.ss_net_profit)                    AS total_store_profit,
         MAX(ss.ss_sold_date_sk)                  AS latest_store_date_sk,
         MIN(ss.ss_item_sk)                       AS sample_item_sk,
         MIN(ss.ss_promo_sk)                      AS sample_promo_sk,
         MIN(ss.ss_store_sk)                      AS sample_store_sk,
         MIN(ss.ss_sold_time_sk)                  AS sample_time_sk
       FROM store_sales ss
       GROUP BY ss.ss_customer_sk
     ),
     ws_agg AS (
       SELECT
         ws.ws_bill_customer_sk                    AS cust_sk,
         SUM(ws.ws_net_paid)                       AS total_web_net_paid,
         SUM(ws.ws_net_profit)                     AS total_web_profit,
         MAX(ws.ws_sold_date_sk)                   AS latest_web_date_sk,
         MIN(ws.ws_item_sk)                        AS sample_item_ws,
         MIN(ws.ws_warehouse_sk)                   AS sample_warehouse_sk,
         MIN(ws.ws_ship_mode_sk)                   AS sample_ship_mode_sk,
         MIN(ws.ws_sold_time_sk)                   AS sample_ws_time_sk
       FROM web_sales ws
       GROUP BY ws.ws_bill_customer_sk
     ),
     wr_agg AS (
       SELECT
         wr.wr_returning_customer_sk               AS cust_sk,
         SUM(wr.wr_net_loss)                       AS total_return_loss,
         MAX(wr.wr_returned_date_sk)               AS latest_return_date_sk,
         MIN(wr.wr_item_sk)                        AS sample_item_wr,
         MIN(wr.wr_returned_time_sk)               AS sample_return_time_sk
       FROM web_returns wr
       GROUP BY wr.wr_returning_customer_sk
     )
SELECT DISTINCT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  cd.cd_gender,
  d_year.d_year,
  i.i_category,
  p.p_discount_active,
  ss.total_store_net_paid,
  ws.total_web_net_paid,
  wr.total_return_loss,
  (ss.total_store_net_paid + ws.total_web_net_paid - COALESCE(wr.total_return_loss, 0)) AS total_net_spend,
  RANK() OVER (ORDER BY (ss.total_store_net_paid + ws.total_web_net_paid - COALESCE(wr.total_return_loss, 0)) DESC) AS spend_rank,
  inv.inv_quantity_on_hand,
  sm.sm_type               AS ship_mode_type,
  w.w_warehouse_name,
  s.s_store_name,
  cp.cp_description,
  t.t_hour
FROM ss_agg ss
LEFT JOIN ws_agg ws ON ss.cust_sk = ws.cust_sk
LEFT JOIN wr_agg wr ON ss.cust_sk = wr.cust_sk
JOIN customer c               ON ss.cust_sk = c.c_customer_sk
JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_year          ON ss.latest_store_date_sk = d_year.d_date_sk
JOIN item i                   ON ss.sample_item_sk = i.i_item_sk
JOIN promotion p              ON ss.sample_promo_sk = p.p_promo_sk
JOIN store s                  ON ss.sample_store_sk = s.s_store_sk
JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d_year.d_date_sk
JOIN warehouse w              ON ws.sample_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm             ON ws.sample_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp          ON cp.cp_start_date_sk = d_year.d_date_sk
                                 AND cp.cp_end_date_sk = d_year.d_date_sk
JOIN time_dim t               ON ss.sample_time_sk = t.t_time_sk
WHERE d_year.d_year = 2001
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  cd.cd_gender,
  d_year.d_year,
  i.i_category,
  p.p_discount_active,
  ss.total_store_net_paid,
  ws.total_web_net_paid,
  wr.total_return_loss,
  inv.inv_quantity_on_hand,
  sm.sm_type,
  w.w_warehouse_name,
  s.s_store_name,
  cp.cp_description,
  t.t_hour
ORDER BY total_net_spend DESC
LIMIT 100
