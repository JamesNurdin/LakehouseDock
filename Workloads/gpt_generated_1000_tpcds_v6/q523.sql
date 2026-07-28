WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_returning_customer_sk,
        cr.cr_catalog_page_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
),
agg_returns AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_page_id,
        SUM(fr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        REGEXP_EXTRACT(i.i_item_desc, '([A-Za-z]+)-', 1) AS item_desc_prefix,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name
    FROM filtered_returns fr
    JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON fr.cr_item_sk = i.i_item_sk
    JOIN customer c ON fr.cr_returning_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)electronic')
      AND i.i_units LIKE 'Box%'
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_page_id,
        REGEXP_EXTRACT(i.i_item_desc, '([A-Za-z]+)-', 1),
        CONCAT(c.c_first_name, ' ', c.c_last_name)
)
SELECT
    department,
    cp_catalog_page_id,
    total_return_amount,
    return_cnt,
    item_desc_prefix,
    customer_name,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_return_amount DESC) AS dept_rank
FROM agg_returns
ORDER BY dept_rank, total_return_amount DESC
LIMIT 100
