WITH catalog_returns AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        d_start.d_year,
        d_start.d_month_seq,
        COUNT(sr.sr_ticket_number) AS returns_count
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    GROUP BY cp.cp_catalog_page_id, cp.cp_department, cp.cp_type, d_start.d_year, d_start.d_month_seq
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_type,
    d_year,
    d_month_seq,
    returns_count,
    (returns_count * 1.0) / SUM(returns_count) OVER (PARTITION BY d_year, d_month_seq) AS returns_ratio_month,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY returns_count DESC) AS rank_by_returns,
    CASE WHEN returns_count >= 100 THEN 'High' WHEN returns_count >= 50 THEN 'Medium' ELSE 'Low' END AS return_category
FROM catalog_returns
ORDER BY d_year, d_month_seq, rank_by_returns
