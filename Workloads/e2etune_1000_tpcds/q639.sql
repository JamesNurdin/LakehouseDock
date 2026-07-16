WITH returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY cr.cr_returned_date_sk, i.i_category
),
web_page_agg AS (
    SELECT
        wp.wp_creation_date_sk AS creation_date_sk,
        wp.wp_type AS page_type,
        COUNT(*) AS page_cnt
    FROM web_page wp
    GROUP BY wp.wp_creation_date_sk, wp.wp_type
)
SELECT
    d.d_year,
    r.category,
    w.page_type,
    r.total_return_amount,
    r.avg_return_tax,
    r.return_cnt,
    w.page_cnt,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY r.total_return_amount DESC) AS category_rank
FROM returns_agg r
JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
JOIN web_page_agg w ON d.d_date_sk = w.creation_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND r.total_return_amount > 5000
ORDER BY d.d_year, category_rank
LIMIT 30
