/*
  Goal: Compare net sales versus returns by item category for the year 2022, showing detailed rows for sales and returns, subtotals per category, and a grand total. The net amount is calculated with a CASE expression and a profit/loss flag is added.
*/
WITH sales AS (
    SELECT i.i_category AS category,
           cs.cs_ext_sales_price AS amount,
           'sale' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
returns AS (
    SELECT i.i_category AS category,
           cr.cr_return_amount AS amount,
           'return' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
unioned AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    category,
    src,
    SUM(CASE WHEN src = 'sale' THEN amount ELSE -amount END) AS net_amount,
    CASE
        WHEN SUM(CASE WHEN src = 'sale' THEN amount ELSE -amount END) > 0 THEN 'profit'
        ELSE 'loss'
    END AS net_status
FROM unioned
GROUP BY GROUPING SETS (
    (category, src),   -- detailed rows for each type
    (category),        -- subtotal per category (sales + returns)
    ()                 -- grand total
)
ORDER BY
    category NULLS LAST,
    src NULLS LAST
