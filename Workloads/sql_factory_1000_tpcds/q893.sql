WITH page_type_agg AS (
    SELECT
        cp.cp_catalog_page_number,
        cp.cp_type,
        SUM(cr.cr_return_amount) AS page_return_amount
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_catalog_page_number, cp.cp_type
)
SELECT
    cp_catalog_page_number,
    cp_type,
    page_return_amount,
    SUM(page_return_amount) OVER (PARTITION BY cp_type ORDER BY cp_catalog_page_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount,
    ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY page_return_amount DESC) AS return_amount_rank
FROM page_type_agg
ORDER BY cp_type, cp_catalog_page_number
