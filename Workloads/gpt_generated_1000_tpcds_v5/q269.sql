WITH store_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        sr.sr_ticket_number,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_ship_cost,
        CASE WHEN sr.sr_return_amt_inc_tax > 1000 THEN 'High' ELSE 'Low' END AS return_category
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_amt_inc_tax > 500
      AND sr.sr_return_ship_cost < 100
      AND cd.cd_purchase_estimate BETWEEN 5000 AND 8000
      AND cd.cd_dep_employed_count >= 2
)
SELECT
    sd.cd_gender,
    sd.cd_marital_status,
    sd.return_category,
    COUNT(DISTINCT sd.sr_ticket_number) AS return_count,
    SUM(sd.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    AVG(cr.cr_store_credit) AS avg_store_credit,
    MIN(cr.cr_net_loss) AS min_net_loss,
    MAX(cr.cr_net_loss) AS max_net_loss
FROM store_demo sd
JOIN catalog_returns cr
  ON cr.cr_refunded_cdemo_sk = sd.cd_demo_sk
WHERE cr.cr_store_credit > 100
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_returning_cdemo_sk = sd.cd_demo_sk
          AND cr2.cr_return_amount > 200
      )
GROUP BY sd.cd_gender, sd.cd_marital_status, sd.return_category
ORDER BY total_return_amount_inc_tax DESC
LIMIT 100
