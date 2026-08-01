WITH combined AS (
    SELECT
        cr.cr_reason_sk AS reason_sk,
        r.r_reason_desc AS reason_desc,
        t.t_hour AS return_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_amount > 100
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY cr.cr_reason_sk, r.r_reason_desc, t.t_hour

    UNION ALL

    SELECT
        wr.wr_reason_sk AS reason_sk,
        r.r_reason_desc AS reason_desc,
        t.t_hour AS return_hour,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count,
        CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS return_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_amt > 100
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY wr.wr_reason_sk, r.r_reason_desc, t.t_hour
)
SELECT
    c.reason_sk,
    c.reason_desc,
    c.return_hour,
    c.total_return_amount,
    c.return_count,
    c.return_category,
    (SELECT SUM(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_reason_sk = c.reason_sk) AS catalog_return_total_for_reason
FROM combined c
ORDER BY c.total_return_amount DESC
LIMIT 100
