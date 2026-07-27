WITH returns_sales AS (
    SELECT
        wr.wr_returning_customer_sk AS returning_customer_sk,
        ws.ws_bill_customer_sk AS bill_customer_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_ship_cost
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_amt > 1000
      AND ws.ws_net_paid_inc_tax > 500
)
SELECT
    'return' AS src,
    returning_customer_sk AS customer_sk,
    SUM(wr_return_amt) AS metric1,
    SUM(wr_net_loss) AS metric2,
    COUNT(*) AS metric3
FROM returns_sales
GROUP BY returning_customer_sk

UNION ALL

SELECT
    'sale' AS src,
    bill_customer_sk AS customer_sk,
    SUM(ws_net_paid_inc_tax) AS metric1,
    SUM(ws_ext_ship_cost) AS metric2,
    COUNT(*) AS metric3
FROM returns_sales
GROUP BY bill_customer_sk

LIMIT 100
