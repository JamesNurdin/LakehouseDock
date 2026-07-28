WITH high_risk_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk'
)
SELECT
    r.r_reason_desc AS reason,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    'Catalog' AS source
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_refunded_customer_sk IN (SELECT c_customer_sk FROM high_risk_customers)
   OR cr.cr_returning_customer_sk IN (SELECT c_customer_sk FROM high_risk_customers)
GROUP BY r.r_reason_desc
UNION ALL
SELECT
    r.r_reason_desc AS reason,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    'Store' AS source
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_customer_sk IN (SELECT c_customer_sk FROM high_risk_customers)
GROUP BY r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
