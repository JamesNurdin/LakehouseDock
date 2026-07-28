WITH catalog_data AS (
    SELECT
        d.d_year,
        i.i_category,
        cp.cp_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_level,
        'catalog' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_category, cp.cp_type
),
web_data AS (
    SELECT
        d.d_year,
        i.i_category,
        CAST(NULL AS varchar) AS cp_type,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_level,
        'web' AS src
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_category
)
SELECT
    d_year,
    i_category,
    cp_type,
    src,
    total_return_amount,
    total_net_loss,
    amount_level,
    ROW_NUMBER() OVER (PARTITION BY src ORDER BY total_return_amount DESC) AS rank_within_src
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) combined
ORDER BY src, total_return_amount DESC
LIMIT 100
