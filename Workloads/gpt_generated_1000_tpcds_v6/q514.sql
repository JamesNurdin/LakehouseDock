WITH catalog_agg AS (
    SELECT
        'catalog' AS source_type,
        cp.cp_department AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY cp.cp_department
    HAVING SUM(cr.cr_return_amount) > 5000
),
web_agg AS (
    SELECT
        'web' AS source_type,
        ws.web_site_id AS category,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        CASE WHEN SUM(wr.wr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY ws.web_site_id
    HAVING SUM(wr.wr_return_amt) > 5000
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_return_amount DESC
LIMIT 100
