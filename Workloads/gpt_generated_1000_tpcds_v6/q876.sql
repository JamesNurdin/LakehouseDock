WITH joined_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    i.i_category,
    cd_bill.cd_gender AS bill_gender,
    wp.wp_type,
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_fee,
    cd_refunded.cd_gender AS refunded_gender,
    cd_returning.cd_gender AS returning_gender,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_state AS returning_state,
    web_site.web_name
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
  LEFT JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
  LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
  LEFT JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
  LEFT JOIN item i_ret
    ON wr.wr_item_sk = i_ret.i_item_sk
),
agg_data AS (
  SELECT
    web_name,
    i_category,
    bill_gender,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    CASE
      WHEN SUM(ws_net_profit) > 100000 THEN 'High'
      ELSE 'Medium'
    END AS profit_level
  FROM joined_data
  GROUP BY
    web_name,
    i_category,
    bill_gender
  HAVING
    SUM(ws_net_profit) > 50000
)
SELECT
  web_name,
  i_category,
  bill_gender,
  total_net_profit,
  total_sales,
  total_return_amount,
  order_cnt,
  profit_level,
  SUM(total_net_profit) OVER (
    PARTITION BY web_name
    ORDER BY total_net_profit DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_profit_by_site
FROM agg_data
ORDER BY total_net_profit DESC
LIMIT 100
