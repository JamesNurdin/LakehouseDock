WITH sampled_items AS (
    SELECT i_item_sk, i_current_price
    FROM item TABLESAMPLE BERNOULLI (10)
),

sales_agg AS (
    SELECT
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY 1
),

catalog_returns_agg AS (
    SELECT
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY 1
),

web_returns_agg AS (
    SELECT
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY 1
),

sales_vs_catalog_full AS (
    SELECT
        COALESCE(s.month, c.month) AS month,
        s.total_sales,
        c.total_net_loss,
        s.total_sales - c.total_net_loss AS net_sales_minus_returns
    FROM sales_agg s
    FULL OUTER JOIN catalog_returns_agg c
        ON s.month = c.month
)

SELECT
    fc.month,
    'Catalog' AS source_type,
    COALESCE(cr.total_net_loss, 0) AS net_loss,
    (SELECT avg(i_current_price) FROM sampled_items) AS avg_sampled_item_price,
    fc.net_sales_minus_returns
FROM
    sales_vs_catalog_full fc
LEFT JOIN catalog_returns_agg cr
    ON fc.month = cr.month
WHERE
    EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
          AND DATE_TRUNC('month', d2.d_date) = fc.month
          AND cr2.cr_return_quantity > 0
    )
UNION
SELECT
    fw.month,
    'Web' AS source_type,
    COALESCE(wr.total_net_loss, 0) AS net_loss,
    (SELECT avg(i_current_price) FROM sampled_items) AS avg_sampled_item_price,
    fw.net_sales_minus_returns
FROM
    sales_vs_catalog_full fw
LEFT JOIN web_returns_agg wr
    ON fw.month = wr.month
WHERE
    fw.month IN (SELECT month FROM web_returns_agg)
ORDER BY
    month,
    source_type
LIMIT 100
