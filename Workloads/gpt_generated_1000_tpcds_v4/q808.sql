WITH reason_filtered AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        CASE
            WHEN regexp_extract(r.r_reason_desc, '(Did not) (.+)', 1) = 'Did not' THEN 'DidNot'
            ELSE 'Other'
        END AS reason_category
    FROM reason r
    WHERE r.r_reason_desc LIKE '%size%' OR r.r_reason_desc LIKE '%color%'
)
SELECT
    rf.r_reason_desc,
    rf.reason_category,
    COUNT(sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(CASE WHEN sr.sr_return_tax > 20 THEN sr.sr_return_tax ELSE 0 END) AS high_tax_total,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    CONCAT('Reason: ', rf.r_reason_desc) AS reason_label,
    (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) AS overall_avg_net_loss
FROM store_returns sr
JOIN reason_filtered rf
    ON sr.sr_reason_sk = rf.r_reason_sk
WHERE sr.sr_return_ship_cost > 20
  AND EXISTS (
        SELECT 1
        FROM reason r3
        WHERE r3.r_reason_sk = sr.sr_reason_sk
          AND regexp_like(r3.r_reason_desc, 'Did not.*')
      )
GROUP BY rf.r_reason_desc, rf.reason_category
ORDER BY total_net_loss DESC
LIMIT 100
