WITH date_filter AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_year = 2002
)
SELECT
    entity_id,
    entity_type,
    d_year,
    total_return_amt,
    metric_on_date,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_return_amt DESC) AS rank_in_type
FROM (
    SELECT
        c.c_customer_id AS entity_id,
        'customer' AS entity_type,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = d.d_date_sk
        ) AS metric_on_date
    FROM store_returns sr
    JOIN date_filter d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IN (
        SELECT r2.r_reason_desc
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%defect%'
    )
    GROUP BY c.c_customer_id, d.d_year, d.d_date_sk

    UNION ALL

    SELECT
        cp.cp_catalog_page_id AS entity_id,
        'catalog_page' AS entity_type,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        (
            SELECT MAX(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = d.d_date_sk
        ) AS metric_on_date
    FROM store_returns sr
    JOIN date_filter d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON (cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk)
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cp.cp_department IS NOT NULL
    GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_date_sk
) AS combined
WHERE total_return_amt > 0
ORDER BY total_return_amt DESC
LIMIT 100
