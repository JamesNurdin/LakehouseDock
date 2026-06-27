WITH sales AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY ds.d_year, ds.d_moy, i.i_category
),
returns AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY ds.d_year, ds.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_returns, 0) / s.total_sales ELSE 0 END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.i_category = r.i_category
ORDER BY return_rate DESC, s.total_sales DESC
LIMIT 20
