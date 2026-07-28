WITH catalog_ret AS (
    SELECT
        'catalog' AS return_source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM
        tpcds.catalog_returns cr
        JOIN tpcds.catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN tpcds.date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_quarter_seq = 2
        AND cp.cp_department = 'Books'
),
store_ret AS (
    SELECT
        'store' AS return_source,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM
        tpcds.store_returns sr
        JOIN tpcds.date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_quarter_seq = 2
        AND sr.sr_store_sk = 5
)
SELECT * FROM catalog_ret
UNION ALL
SELECT * FROM store_ret
ORDER BY total_return_amount DESC
