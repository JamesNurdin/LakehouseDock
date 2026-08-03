WITH
  store_info AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_net_profit,
      ss.ss_net_paid,
      d.d_date,
      d.d_year,
      t.t_hour,
      t.t_meal_time,
      i.i_item_id,
      i.i_current_price,
      c.c_customer_id,
      cd.cd_gender AS c_gender,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      p.p_promo_name,
      p.p_cost,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  ),
  web_info AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      d2.d_date AS web_date,
      d2.d_year AS web_year,
      t2.t_hour AS web_hour,
      t2.t_meal_time AS web_meal_time,
      i2.i_item_id AS web_item_id,
      i2.i_current_price AS web_item_price,
      c2.c_customer_id AS web_customer_id,
      cd2.cd_gender AS web_gender,
      hd2.hd_income_band_sk AS web_income_band,
      ws.ws_net_paid,
      wi.wr_return_quantity AS web_return_qty,
      wi.wr_net_loss AS web_return_loss,
      ws.ws_web_site_sk,
      ws_site.web_name
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wi ON ws.ws_order_number = wi.wr_order_number
  ),
  catalog_info AS (
    SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      d3.d_date AS cat_date,
      d3.d_year AS cat_year,
      t3.t_hour AS cat_hour,
      t3.t_meal_time AS cat_meal_time,
      i3.i_item_id AS cat_item_id,
      i3.i_current_price AS cat_item_price,
      c3.c_customer_id AS cat_customer_id,
      cd3.cd_gender AS cat_gender,
      hd3.hd_income_band_sk AS cat_income_band,
      cc.cc_name AS call_center_name,
      cp.cp_department,
      cr.cr_return_quantity,
      cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d3 ON cr.cr_returned_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON cr.cr_returned_time_sk = t3.t_time_sk
    JOIN item i3 ON cr.cr_item_sk = i3.i_item_sk
    JOIN customer c3 ON cr.cr_refunded_customer_sk = c3.c_customer_sk
    JOIN customer_demographics cd3 ON cr.cr_refunded_cdemo_sk = cd3.cd_demo_sk
    JOIN household_demographics hd3 ON cr.cr_refunded_hdemo_sk = hd3.hd_demo_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  )
SELECT
  si.d_date AS sold_date,
  si.t_hour,
  si.i_item_id,
  si.c_customer_id,
  si.c_gender,
  si.hd_income_band_sk,
  si.hd_buy_potential,
  si.p_promo_name,
  si.p_cost,
  si.sr_return_quantity,
  si.sr_net_loss,
  wi.web_name,
  wi.ws_net_paid,
  wi.web_return_qty,
  wi.web_return_loss,
  ci.call_center_name,
  ci.cp_department,
  ci.cr_return_quantity,
  ci.cr_net_loss,
  ROW_NUMBER() OVER (ORDER BY si.d_date DESC, si.i_item_id) AS global_row_num,
  ROW_NUMBER() OVER (PARTITION BY si.c_customer_id ORDER BY si.d_date DESC) AS rn_per_customer,
  (SELECT SUM(sr2.sr_net_loss) FROM store_returns sr2 WHERE sr2.sr_ticket_number = si.ss_ticket_number) AS total_return_loss_per_ticket,
  (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_store_profit,
  (SELECT COUNT(DISTINCT c2.c_customer_id) FROM customer c2) AS total_distinct_customers,
  (SELECT COUNT(DISTINCT i2.i_item_id) FROM item i2) AS total_distinct_items
FROM store_info si
FULL OUTER JOIN web_info wi ON si.ss_sold_date_sk = wi.ws_sold_date_sk
FULL OUTER JOIN catalog_info ci ON si.ss_sold_date_sk = ci.cr_returned_date_sk
WHERE
  si.d_year = 2001
  AND si.t_meal_time = 'lunch'
  AND si.i_current_price > 100
  AND si.hd_buy_potential = '5001-10000'
  AND si.p_cost < 5000
  AND si.c_gender = 'M'
  AND si.ss_net_paid > (SELECT AVG(ss_net_paid) FROM store_sales)
ORDER BY global_row_num
LIMIT 100
