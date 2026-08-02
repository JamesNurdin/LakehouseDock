WITH
  sales_orders AS (
    SELECT ws_order_number
    FROM web_sales
  ),
  return_orders AS (
    SELECT wr_order_number
    FROM web_returns
  ),
  sales_without_return AS (
    SELECT ws_order_number FROM sales_orders
    EXCEPT
    SELECT wr_order_number FROM return_orders
  )
SELECT
  cd_bill.cd_gender,
  cd_bill.cd_marital_status,
  hd_bill.hd_buy_potential,
  reason.r_reason_desc,
  COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount
FROM
  web_sales ws
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  LEFT JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN reason
    ON wr.wr_reason_sk = reason.r_reason_sk
  LEFT JOIN customer_demographics cd_refund
    ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  LEFT JOIN household_demographics hd_refund
    ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
  LEFT JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
  INNER JOIN sales_without_return swo
    ON ws.ws_order_number = swo.ws_order_number
WHERE
  ws.ws_order_number IN (
    SELECT wr2.wr_order_number
    FROM web_returns wr2
    WHERE wr2.wr_return_amt_inc_tax > 300
  )
GROUP BY
  ROLLUP (
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    hd_bill.hd_buy_potential,
    reason.r_reason_desc
  )
ORDER BY total_sales DESC
LIMIT 100
