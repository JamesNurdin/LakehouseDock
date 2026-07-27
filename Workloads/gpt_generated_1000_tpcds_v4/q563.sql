WITH
    ws AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_ship_date_sk,
            ws.ws_item_sk,
            ws.ws_ship_mode_sk,
            ws.ws_net_profit,
            ws.ws_bill_cdemo_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_ship_cdemo_sk,
            ws.ws_ship_hdemo_sk,
            ws.ws_quantity
        FROM web_sales ws
    ),
    sr AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_returned_date_sk,
            sr.sr_return_time_sk,
            sr.sr_item_sk,
            sr.sr_cdemo_sk,
            sr.sr_hdemo_sk,
            sr.sr_net_loss
        FROM store_returns sr
    ),
    wr AS (
        SELECT
            wr.wr_order_number,
            wr.wr_returned_date_sk,
            wr.wr_returned_time_sk,
            wr.wr_item_sk,
            wr.wr_refunded_cdemo_sk,
            wr.wr_refunded_hdemo_sk,
            wr.wr_returning_cdemo_sk,
            wr.wr_returning_hdemo_sk,
            wr.wr_net_loss
        FROM web_returns wr
    )
SELECT
    d_ws_sold.d_year AS sale_year,
    i_ws.i_category AS category,
    sm.sm_type AS ship_mode_type,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_returns_cnt
FROM ws
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
  ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN item i_ws
  ON ws.ws_item_sk = i_ws.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_ws_bill
  ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill
  ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_demographics cd_ws_ship
  ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship
  ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
LEFT JOIN sr
  ON sr.sr_item_sk = i_ws.i_item_sk
LEFT JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN customer_demographics cd_wr_ref
  ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
LEFT JOIN household_demographics hd_wr_ref
  ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
LEFT JOIN customer_demographics cd_wr_ret
  ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
LEFT JOIN household_demographics hd_wr_ret
  ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
GROUP BY
    d_ws_sold.d_year,
    i_ws.i_category,
    sm.sm_type
ORDER BY
    total_web_profit DESC
LIMIT 100
