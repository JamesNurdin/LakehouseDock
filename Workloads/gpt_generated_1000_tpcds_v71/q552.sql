WITH sales AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'store' AS source,
        SUM(ss.ss_ext_sales_price - ss.ss_net_paid) AS loss_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        'catalog' AS source,
        SUM(cr.cr_net_loss) AS loss_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 5.00
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    year,
    month_seq,
    source,
    SUM(loss_amount) AS total_loss,
    CASE WHEN SUM(loss_amount) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM combined
GROUP BY year, month_seq, source
HAVING SUM(loss_amount) > 5000
ORDER BY year DESC, month_seq ASC, total_loss DESC
LIMIT 100
