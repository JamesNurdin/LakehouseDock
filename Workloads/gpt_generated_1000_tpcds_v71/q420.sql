WITH joined_data AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    ss.ss_net_paid,
    ws.ws_net_paid,
    ws.ws_net_profit,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_county,
    td.t_hour,
    td.t_am_pm,
    i.inv_quantity_on_hand,
    wp.wp_type
  FROM catalog_returns cr
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE cr.cr_returned_date_sk = 2450843
    AND cr.cr_return_quantity > 2
    AND td.t_am_pm = 'PM'
    AND i.inv_quantity_on_hand > 400
    AND w.w_county = 'Bronx County'
    AND ws.ws_net_profit > 0
    AND wp.wp_type = 'article'
    AND ws.ws_net_profit > (
        SELECT avg(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
    )
)
SELECT
  w_warehouse_id,
  w_warehouse_name,
  w_county,
  t_hour,
  COUNT(DISTINCT cr_returned_date_sk) AS return_days,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(ss_net_paid) AS total_store_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  SUM(ws_net_profit) AS total_web_profit,
  COUNT(DISTINCT cr_return_quantity) AS distinct_return_qty,
  COUNT(DISTINCT ss_net_paid) AS distinct_store_payments,
  COUNT(DISTINCT ws_net_paid) AS distinct_web_payments
FROM joined_data
GROUP BY w_warehouse_id, w_warehouse_name, w_county, t_hour
ORDER BY total_web_profit DESC
LIMIT 100
