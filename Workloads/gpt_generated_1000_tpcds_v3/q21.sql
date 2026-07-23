WITH aggregated AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        d_ret.d_weekend = 'N'
        AND d_ret.d_fy_week_seq BETWEEN 6 AND 12
        AND cp.cp_catalog_number >= 10
        AND w.w_suite_number LIKE 'Suite %'
        AND cr.cr_return_amount > 0
        AND r.r_reason_desc NOT IN ('Promotion Return', 'Late Delivery')
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq
    HAVING
        SUM(cr.cr_return_amount) > 1000
)
SELECT
    a.cp_catalog_page_id,
    a.cp_catalog_number,
    a.w_warehouse_name,
    a.d_year,
    a.d_month_seq,
    a.total_return_amount,
    a.avg_return_amount,
    a.return_count,
    ROW_NUMBER() OVER (PARTITION BY a.cp_catalog_page_id ORDER BY a.total_return_amount DESC) AS rank_within_page,
    (
        SELECT AVG(inner_total) FROM (
            SELECT SUM(cr2.cr_return_amount) AS inner_total
            FROM catalog_returns cr2
            JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
            WHERE cp2.cp_catalog_page_id = a.cp_catalog_page_id
            GROUP BY cr2.cr_warehouse_sk
        ) t
    ) AS avg_total_per_warehouse,
    (
        SELECT COUNT(DISTINCT r2.r_reason_desc)
        FROM reason r2
        JOIN catalog_returns cr3 ON cr3.cr_reason_sk = r2.r_reason_sk
        JOIN catalog_page cp3 ON cr3.cr_catalog_page_sk = cp3.cp_catalog_page_sk
        WHERE cp3.cp_catalog_page_id = a.cp_catalog_page_id
    ) AS distinct_reason_count
FROM aggregated a
WHERE a.total_return_amount > (
    SELECT AVG(total_return_amount) FROM aggregated
)
ORDER BY a.total_return_amount DESC, a.avg_return_amount DESC
LIMIT 100
