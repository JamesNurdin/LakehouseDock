WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM sampled_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid > 100
),
returned_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 50
),
web_returned_orders AS (
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 20
),
intersected AS (
    SELECT order_number FROM sales_orders
    INTERSECT
    SELECT order_number FROM returned_orders
),
final_set AS (
    SELECT order_number FROM intersected
    EXCEPT
    SELECT order_number FROM web_returned_orders
)
SELECT
    order_number,
    CASE WHEN order_number % 2 = 0 THEN 'Even' ELSE 'Odd' END AS parity
FROM final_set
ORDER BY order_number DESC
OFFSET 0 FETCH NEXT 50 ROWS ONLY
