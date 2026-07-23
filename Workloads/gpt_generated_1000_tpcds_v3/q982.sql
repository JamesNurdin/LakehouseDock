WITH
  sales AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      ss.ss_ext_discount_amt,
      ss.ss_sold_time_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      i.i_wholesale_cost,
      c.c_birth_year,
      td.t_hour
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
  ),
  returns AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_net_loss,
      sr.sr_return_quantity,
      r.r_reason_desc,
      td.t_hour AS return_hour,
      c.c_customer_sk,
      cd.cd_demo_sk,
      ca.ca_address_sk
    FROM store_returns sr
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_desc = 'Damaged'
  ),
  catalog_ret AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_order_number,
      cr.cr_net_loss,
      cr.cr_return_quantity,
      i.i_item_id,
      i.i_category,
      i.i_wholesale_cost,
      td.t_hour AS return_hour,
      w.w_state,
      sm.sm_type,
      r.r_reason_desc,
      c_ref.c_customer_sk AS refunded_customer_sk,
      c_ret.c_customer_sk AS returning_customer_sk,
      cd_ref.cd_demo_sk AS refunded_demo_sk,
      cd_ret.cd_demo_sk AS returning_demo_sk,
      ca_ref.ca_address_sk AS refunded_addr_sk,
      ca_ret.ca_address_sk AS returning_addr_sk
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_ref
      ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret
      ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ref
      ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
      ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
      ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE w.w_state = 'CA'
  ),
  web AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_net_profit,
      ws.ws_ext_discount_amt,
      i.i_item_id,
      i.i_category,
      i.i_wholesale_cost,
      td.t_hour AS web_hour,
      w.w_state,
      sm.sm_type,
      c.c_birth_year
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE w.w_state = 'CA'
  )
SELECT
  s.i_item_id,
  s.i_product_name,
  s.t_hour,
  s.i_category,
  SUM(s.ss_net_profit) AS total_sales_net_profit,
  SUM(COALESCE(r.sr_net_loss, 0)) AS total_store_return_loss,
  SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
  COUNT(DISTINCT s.ss_ticket_number) AS sales_transactions,
  COUNT(DISTINCT r.sr_ticket_number) AS store_return_transactions,
  COUNT(DISTINCT cr.cr_order_number) AS catalog_return_transactions,
  AVG(s.ss_ext_discount_amt) AS avg_sales_discount,
  RANK() OVER (PARTITION BY s.i_category ORDER BY SUM(s.ss_net_profit) DESC) AS category_profit_rank,
  (SELECT AVG(ws.ws_net_profit)
   FROM web_sales ws
   JOIN time_dim td
     ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17) AS overall_avg_web_profit
FROM sales s
LEFT JOIN returns r
  ON s.ss_item_sk = r.sr_item_sk
  AND s.ss_ticket_number = r.sr_ticket_number
LEFT JOIN catalog_ret cr
  ON s.ss_item_sk = cr.cr_item_sk
LEFT JOIN web w
  ON s.ss_item_sk = w.ws_item_sk
WHERE s.i_wholesale_cost > 20.0
  AND s.t_hour BETWEEN 9 AND 17
  AND s.c_birth_year > 1970
  AND s.i_category = 'Electronics'
GROUP BY s.i_item_id, s.i_product_name, s.t_hour, s.i_category
HAVING SUM(s.ss_net_profit) > 1000
ORDER BY total_sales_net_profit DESC
LIMIT 100
