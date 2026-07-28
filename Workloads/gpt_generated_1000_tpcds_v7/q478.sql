WITH store_web AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_refunded_cash,
        wp.wp_link_count,
        wp.wp_max_ad_count
    FROM date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND r.r_reason_desc = 'Damaged'
      AND wp.wp_link_count >= 16
      AND sr.sr_return_amt > 20.0
      AND wr.wr_return_quantity <= 3
)
SELECT
    d_year,
    r_reason_desc,
    COUNT(*) AS total_returns,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(wr_return_amt) AS total_web_return_amt,
    AVG(sr_return_quantity) AS avg_store_return_qty,
    MAX(wr_refunded_cash) AS max_web_refunded_cash,
    (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) AS overall_avg_store_return_amt
FROM store_web
GROUP BY d_year, r_reason_desc
ORDER BY total_store_return_amt DESC
LIMIT 100
