SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    wp.wp_url,
    sm.sm_carrier,
    rs.r_reason_desc,
    td_sold.t_time AS sold_hour,
    td_return.t_time AS return_hour,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_url ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM tpcds.web_sales ws
JOIN tpcds.time_dim td_sold
  ON ws.ws_sold_time_sk = td_sold.t_time_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
JOIN tpcds.reason rs
  ON wr.wr_reason_sk = rs.r_reason_sk
JOIN tpcds.time_dim td_return
  ON wr.wr_returned_time_sk = td_return.t_time_sk
WHERE td_sold.t_time BETWEEN 5 AND 12
  AND td_sold.t_meal_time = 'dinner'
  AND wp.wp_image_count > 2
  AND sm.sm_carrier = 'UPS'
  AND rs.r_reason_desc LIKE '%damaged%'
  AND wr.wr_return_tax > 10
  AND ws.ws_quantity >= 2
  AND ws.ws_net_profit > 0
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_tax > 20
      )
ORDER BY profit_rank
LIMIT 100
