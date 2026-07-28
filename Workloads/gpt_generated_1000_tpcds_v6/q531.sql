SELECT
    cd.cd_gender,
    r.r_reason_desc,
    CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category,
    CASE WHEN sr.sr_return_amt > (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) THEN 'Above Avg' ELSE 'Below Avg' END AS amt_category,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_return_amt
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_marital_status = 'U'
  AND cd.cd_dep_employed_count >= 2
  AND r.r_reason_desc LIKE '%color%'
  AND sr.sr_return_amt > 100
  AND sr.sr_return_tax > 0
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        JOIN reason r_ex
            ON sr_ex.sr_reason_sk = r_ex.r_reason_sk
        WHERE sr_ex.sr_cdemo_sk = cd.cd_demo_sk
          AND r_ex.r_reason_id = 'AAAAAAAADBAAAAAA'
    )
GROUP BY
    cd.cd_gender,
    r.r_reason_desc,
    CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END,
    CASE WHEN sr.sr_return_amt > (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) THEN 'Above Avg' ELSE 'Below Avg' END
ORDER BY total_return_amt DESC
LIMIT 100
