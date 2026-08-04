WITH
  sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (5)
  ),
  set_store_orders AS (
    SELECT ss_ticket_number FROM store_sales
  ),
  set_store_return_tickets AS (
    SELECT sr_ticket_number FROM store_returns
  ),
  set_web_orders AS (
    SELECT ws_order_number FROM web_sales
  ),
  set_web_return_orders AS (
    SELECT wr_order_number FROM web_returns
  ),
  deep_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      i.i_item_id,
      s.s_store_name,
      p.p_promo_name,
      cd.cd_gender,
      ca.ca_state,
      cs.cs_order_number,
      cc.cc_name,
      sm_cs.sm_type AS cs_ship_type,
      cr.cr_return_amount,
      sr.sr_return_amt,
      ws.ws_order_number,
      wp.wp_url,
      sm_ws.sm_type AS ws_ship_type,
      wr.wr_return_amt
    FROM store_sales ss
    JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN sampled_item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_order_number = cs.cs_order_number
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE ss.ss_ticket_number IN (
          SELECT ticket FROM (
               SELECT ss_ticket_number AS ticket FROM set_store_orders
               EXCEPT
               SELECT sr_ticket_number FROM set_store_return_tickets
          )
    )
    AND ws.ws_order_number IN (
          SELECT order_num FROM (
               SELECT ws_order_number AS order_num FROM set_web_orders
               INTERSECT
               SELECT wr_order_number FROM set_web_return_orders
          )
    )
  )
SELECT
    ROW_NUMBER() OVER (ORDER BY ss_sold_date_sk) AS row_num,
    ss_ticket_number,
    i_item_id,
    s_store_name,
    p_promo_name,
    cd_gender,
    ca_state,
    cs_order_number,
    cc_name,
    cs_ship_type,
    cr_return_amount,
    sr_return_amt,
    ws_order_number,
    wp_url,
    ws_ship_type,
    wr_return_amt
FROM deep_join
ORDER BY ss_sold_date_sk
OFFSET 0 LIMIT 100
