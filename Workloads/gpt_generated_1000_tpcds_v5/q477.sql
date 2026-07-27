WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND r.r_reason_desc LIKE '%price%'
      AND sr.sr_store_sk IN (646, 817)
      AND sr.sr_return_amt > 10
)
SELECT
    fr.d_year,
    fr.d_month_seq,
    fr.r_reason_desc,
    w.web_company_name,
    CASE WHEN fr.sr_net_loss > 0 THEN 'Loss' ELSE 'No Loss' END AS loss_flag,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_return_quantity) AS avg_return_qty,
    COUNT(fr.sr_ticket_number) AS return_ticket_cnt,
    MIN(fr.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fr.sr_return_amt_inc_tax) AS max_return_inc_tax
FROM filtered_returns fr
JOIN web_site w ON w.web_open_date_sk = fr.sr_returned_date_sk
WHERE w.web_company_name = 'pri'
GROUP BY
    fr.d_year,
    fr.d_month_seq,
    fr.r_reason_desc,
    w.web_company_name,
    CASE WHEN fr.sr_net_loss > 0 THEN 'Loss' ELSE 'No Loss' END
ORDER BY total_return_amt DESC
LIMIT 100
