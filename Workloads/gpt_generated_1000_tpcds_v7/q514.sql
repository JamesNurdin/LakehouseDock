WITH catalog_ret AS (
    SELECT
        d.d_year AS year,
        'catalog' AS channel,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns AS cr
    JOIN catalog_sales AS cs
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim AS d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cs.cs_sales_price > 100
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
),
web_ret AS (
    SELECT
        d.d_year AS year,
        'web' AS channel,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns AS wr
    JOIN web_page AS wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim AS d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wp.wp_type = 'content'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM web_ret
ORDER BY year, channel
