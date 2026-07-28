WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 1000
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT reason_desc,
       total_return_amount,
       return_cnt,
       'catalog' AS source
FROM catalog_agg
UNION ALL
SELECT reason_desc,
       total_return_amount,
       return_cnt,
       'web' AS source
FROM web_agg
ORDER BY total_return_amount DESC
LIMIT 100
