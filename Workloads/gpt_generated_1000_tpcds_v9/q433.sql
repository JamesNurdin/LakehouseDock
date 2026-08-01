WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category
),
combined AS (
    SELECT category, 'sales'   AS metric, total_sales  AS amount FROM sales_agg
    UNION ALL
    SELECT category, 'returns' AS metric, total_returns AS amount FROM returns_agg
)
SELECT
    c.category,
    c.metric,
    c.amount,
    (
        SELECT SUM(cs.cs_net_paid)
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ) AS total_sales_year,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ) AS total_returns_year
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM returns_agg ra
    WHERE ra.category = c.category
)
ORDER BY c.amount DESC
LIMIT 100
