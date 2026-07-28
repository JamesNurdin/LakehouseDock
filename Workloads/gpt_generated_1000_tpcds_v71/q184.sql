WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_fee
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND cr.cr_return_amount > 1000
      AND cr.cr_return_tax < 200
)
SELECT
    d.d_year,
    d.d_month_seq,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount,
    SUM(CASE WHEN fr.cr_net_loss > 500 THEN fr.cr_net_loss ELSE 0 END) AS high_loss_sum
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store s
    WHERE s.s_closed_date_sk = d.d_date_sk
      AND s.s_state = 'CA'
      AND s.s_gmt_offset = -5.00
)
GROUP BY d.d_year, d.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
