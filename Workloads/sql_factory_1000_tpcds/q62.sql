WITH order_returns AS (
    SELECT cs.cs_bill_customer_sk,
           cs.cs_bill_addr_sk,
           cs.cs_quantity AS sold_qty,
           COALESCE(wr.wr_return_quantity, 0) AS returned_qty,
           cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
           cs.cs_sold_date_sk
    FROM catalog_sales cs
    LEFT JOIN web_returns wr ON cs.cs_order_number = wr.wr_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
)
SELECT o.cs_bill_customer_sk AS customer_sk,
       ca.ca_city,
       ca.ca_state,
       SUM(o.sold_qty) AS total_sold_qty,
       SUM(o.returned_qty) AS total_returned_qty,
       SUM(o.net_paid_inc_tax) AS total_net_paid_inc_tax,
       PERCENT_RANK() OVER (ORDER BY SUM(o.returned_qty) DESC) AS return_quantity_percentile,
       CASE WHEN SUM(o.returned_qty) > 0 THEN 'Returned' ELSE 'No Return' END AS return_indicator
FROM order_returns o
JOIN customer_address ca ON o.cs_bill_addr_sk = ca.ca_address_sk
GROUP BY o.cs_bill_customer_sk, ca.ca_city, ca.ca_state
HAVING SUM(o.sold_qty) >= 5
ORDER BY return_quantity_percentile DESC
LIMIT 20
