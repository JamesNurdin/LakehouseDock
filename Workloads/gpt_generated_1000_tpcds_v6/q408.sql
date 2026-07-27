WITH combined AS (
    SELECT
        d.d_year,
        d.d_qoy,
        d.d_current_week,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        sr.sr_return_amt,
        wr.wr_return_amt,
        wp.wp_max_ad_count,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_qoy = 2
      AND d.d_current_week = 'N'
      AND wp.wp_max_ad_count >= 2
      AND cr.cr_refunded_cash > 100
)
SELECT
    d_year,
    d_qoy,
    return_category,
    COUNT(*) AS cnt,
    SUM(cr_return_amount) AS total_cr_return,
    SUM(sr_return_amt) AS total_sr_return,
    SUM(wr_return_amt) AS total_wr_return,
    AVG(cr_refunded_cash) AS avg_refunded_cash
FROM combined
GROUP BY d_year, d_qoy, return_category
HAVING SUM(cr_return_amount) > 500
ORDER BY total_cr_return DESC
LIMIT 100
