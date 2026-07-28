WITH sales_returns AS (
    SELECT
        c.c_customer_id,
        ws.ws_order_number,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer cr
        ON wr.wr_refunded_customer_sk = cr.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_list_price BETWEEN 100 AND 200
      AND wr.wr_account_credit < 200
      AND ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY c.c_customer_id, ws.ws_order_number
)
SELECT
    sr.c_customer_id,
    sr.ws_order_number,
    sr.total_sales,
    sr.total_returns,
    (sr.total_sales - COALESCE(sr.total_returns, 0)) AS net_profit,
    CASE
        WHEN (sr.total_sales - COALESCE(sr.total_returns, 0)) > (
            SELECT AVG(ws2.ws_net_paid_inc_tax) FROM web_sales ws2
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    RANK() OVER (ORDER BY (sr.total_sales - COALESCE(sr.total_returns, 0)) DESC) AS profit_rank
FROM sales_returns sr
ORDER BY profit_rank
LIMIT 100
