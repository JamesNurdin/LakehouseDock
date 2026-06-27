WITH catalog_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           SUM(cs.cs_net_paid_inc_tax) AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
store_sales_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           SUM(ss.ss_net_paid_inc_tax) AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
returns_agg AS (
    SELECT d.d_year AS year,
           d.d_moy AS month,
           i.i_category AS category,
           SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT 
    COALESCE(cs.year, ss.year, r.year) AS year,
    COALESCE(cs.month, ss.month, r.month) AS month,
    COALESCE(cs.category, ss.category, r.category) AS category,
    COALESCE(cs.net_paid, 0) + COALESCE(ss.net_paid, 0) AS total_sales,
    COALESCE(r.return_amount, 0) AS total_returns,
    COALESCE(cs.net_paid, 0) + COALESCE(ss.net_paid, 0) - COALESCE(r.return_amount, 0) AS net_revenue
FROM catalog_sales_agg cs
FULL OUTER JOIN store_sales_agg ss
    ON cs.year = ss.year
   AND cs.month = ss.month
   AND cs.category = ss.category
FULL OUTER JOIN returns_agg r
    ON COALESCE(cs.year, ss.year) = r.year
   AND COALESCE(cs.month, ss.month) = r.month
   AND COALESCE(cs.category, ss.category) = r.category
WHERE COALESCE(cs.year, ss.year, r.year) = 2001
ORDER BY year, month, category
