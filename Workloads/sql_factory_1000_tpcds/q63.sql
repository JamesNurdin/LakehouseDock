WITH order_returns AS (
    SELECT cs.cs_bill_customer_sk,
           cs.cs_bill_addr_sk,
           cs.cs_quantity AS sold_qty,
           COALESCE(wr.wr_return_quantity, 0) AS returned_qty,
           date_parse(CAST(cs.cs_sold_date_sk AS VARCHAR), '%Y%m%d') AS sold_date
    FROM catalog_sales cs
    LEFT JOIN web_returns wr ON cs.cs_order_number = wr.wr_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
)
SELECT o.cs_bill_customer_sk AS customer_sk,
       ca.ca_state,
       EXTRACT(MONTH FROM o.sold_date) AS month,
       SUM(o.sold_qty) AS total_sold_qty,
       SUM(o.returned_qty) AS total_returned_qty,
       ROUND(SUM(o.returned_qty) * 100.0 / NULLIF(SUM(o.sold_qty), 0), 2) AS return_percent,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(o.returned_qty) DESC) AS state_rank
FROM order_returns o
JOIN customer_address ca ON o.cs_bill_addr_sk = ca.ca_address_sk
GROUP BY o.cs_bill_customer_sk, ca.ca_state, EXTRACT(MONTH FROM o.sold_date)
HAVING SUM(o.sold_qty) >= 3
ORDER BY ca.ca_state, month
