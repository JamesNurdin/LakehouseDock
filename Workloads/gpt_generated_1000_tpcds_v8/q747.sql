WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_net_paid,
    ws.ws_net_profit,
    wr.wr_returned_date_sk,
    wr.wr_return_quantity,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn_item
  FROM web_sales ws
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  WHERE ws.ws_web_site_sk = (
          SELECT MIN(web_site_sk)
          FROM web_site
          WHERE web_tax_percentage > 0.05
        )
    AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = ws.ws_item_sk
            AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
        )
)

SELECT bill_customer_sk
FROM (
        SELECT DISTINCT ws_bill_customer_sk AS bill_customer_sk
        FROM sales_returns
        WHERE profit_flag = 'PROFIT'
     ) AS profit_customers

EXCEPT

SELECT returning_customer_sk
FROM (
        SELECT DISTINCT wr_returning_customer_sk AS returning_customer_sk
        FROM web_returns
        WHERE wr_return_amt > 1000
     ) AS high_return_customers

LIMIT 100
