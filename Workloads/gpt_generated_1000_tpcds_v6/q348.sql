WITH sales_customers AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_bill_customer_sk
    HAVING sum(cs.cs_net_profit) > 5000
),
returns_customers AS (
    SELECT wr.wr_returning_customer_sk AS customer_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_net_loss > 1000
      AND EXISTS (
          SELECT 1
          FROM inventory i
          JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
          WHERE i.inv_item_sk = wr.wr_item_sk
            AND d2.d_year = 2001
            AND i.inv_quantity_on_hand > 0
      )
)
SELECT DISTINCT customer_sk
FROM (
    SELECT customer_sk FROM sales_customers
    UNION
    SELECT customer_sk FROM returns_customers
) combined
ORDER BY customer_sk
LIMIT 100
