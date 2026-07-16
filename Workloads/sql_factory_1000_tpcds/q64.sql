WITH order_returns AS (
    SELECT cs.cs_bill_customer_sk,
           cs.cs_bill_addr_sk,
           cs.cs_quantity AS sold_qty,
           COALESCE(wr.wr_return_quantity, 0) AS returned_qty,
           cs.cs_ship_mode_sk,
           cs.cs_sold_date_sk
    FROM catalog_sales cs
    LEFT JOIN web_returns wr ON cs.cs_order_number = wr.wr_order_number
    WHERE cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
)
SELECT o.cs_bill_customer_sk AS customer_sk,
       ca.ca_city,
       ca.ca_state,
       sm.cs_ship_mode_sk,
       SUM(o.sold_qty) AS total_sold_qty,
       SUM(o.returned_qty) AS total_returned_qty,
       ROUND(100.0 * SUM(o.returned_qty) / NULLIF(SUM(o.sold_qty), 0), 2) AS return_rate_pct,
       MAX(o.cs_sold_date_sk) AS last_sold_date_sk
FROM order_returns o
JOIN customer_address ca ON o.cs_bill_addr_sk = ca.ca_address_sk
JOIN (SELECT DISTINCT cs_ship_mode_sk FROM catalog_sales) sm ON o.cs_ship_mode_sk = sm.cs_ship_mode_sk
GROUP BY o.cs_bill_customer_sk, ca.ca_city, ca.ca_state, sm.cs_ship_mode_sk
HAVING SUM(o.sold_qty) >= 6
ORDER BY return_rate_pct DESC
LIMIT 15
