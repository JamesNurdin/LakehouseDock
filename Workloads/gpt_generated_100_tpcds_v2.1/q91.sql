WITH filtered_data AS (
    SELECT
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_reversed_charge,
        wp.wp_web_page_id,
        wp.wp_max_ad_count,
        wp.wp_rec_start_date,
        wp.wp_rec_end_date,
        r.r_reason_id,
        r.r_reason_desc
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_max_ad_count >= 2
      AND wp.wp_rec_start_date >= DATE '2022-01-01'
      AND wp.wp_rec_end_date <= DATE '2022-12-31'
      AND r.r_reason_id IN ('AAAAAAAAABAAAAAA', 'AAAAAAAABAAAAAAA')
      AND r.r_reason_desc LIKE '%price%'
      AND wr.wr_return_tax > 20.00
      AND wr.wr_return_amt_inc_tax BETWEEN 100 AND 500
      AND wr.wr_reversed_charge < 200
)
SELECT
    fd.wp_web_page_id,
    fd.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(fd.wr_return_amt) AS total_return_amount,
    AVG(fd.wr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
    MIN(fd.wr_return_tax) AS min_return_tax,
    MAX(fd.wr_return_tax) AS max_return_tax,
    SUM(fd.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(fd.wr_net_loss) > 1000 THEN 'HighLoss'
        ELSE 'LowLoss'
    END AS loss_category,
    SUM(CASE WHEN fd.wr_return_tax > 30 THEN fd.wr_return_amt ELSE 0 END) AS high_tax_return_amount
FROM filtered_data fd
GROUP BY fd.wp_web_page_id, fd.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
