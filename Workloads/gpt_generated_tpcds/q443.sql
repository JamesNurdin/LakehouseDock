WITH returns_by_page AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        dr.d_year AS return_year,
        dr.d_date AS return_date,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_amount,
        AVG(cr.cr_return_amount) AS avg_amount,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN date_dim ds
        ON cp.cp_start_date_sk = ds.d_date_sk
    JOIN date_dim de
        ON cp.cp_end_date_sk = de.d_date_sk
    WHERE dr.d_year = 2001
      AND dr.d_date BETWEEN ds.d_date AND de.d_date
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        dr.d_year,
        dr.d_date
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    return_year,
    return_date,
    total_quantity,
    total_amount,
    avg_amount,
    return_count,
    ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rank_by_amount
FROM returns_by_page
ORDER BY total_amount DESC
LIMIT 10
