WITH per_page_reason AS (
    SELECT
        wp.wp_web_page_id,
        r.r_reason_desc,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(wr.wr_refunded_cash) AS avg_refunded_cash
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_max_ad_count >= 1
      AND wp.wp_type = 'content'
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND wr.wr_return_amt_inc_tax > 100
    GROUP BY wp.wp_web_page_id, r.r_reason_desc
)
SELECT DISTINCT
    ppr.wp_web_page_id,
    COUNT(*) AS reason_cnt,
    SUM(ppr.total_return_inc_tax) AS sum_total_return_inc_tax,
    AVG(ppr.avg_refunded_cash) AS avg_refunded_cash_over_reasons,
    (
        SELECT MAX(wr3.wr_return_amt_inc_tax)
        FROM web_returns wr3
        JOIN web_page wp3 ON wr3.wr_web_page_sk = wp3.wp_web_page_sk
        WHERE wp3.wp_web_page_id = ppr.wp_web_page_id
    ) AS max_return_amt_inc_tax
FROM per_page_reason ppr
WHERE ppr.returns_cnt > 5
  AND ppr.total_return_inc_tax > 500
GROUP BY ppr.wp_web_page_id
HAVING COUNT(*) >= 2
ORDER BY sum_total_return_inc_tax DESC
LIMIT 100
