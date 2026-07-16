WITH filtered_returns AS (
    SELECT
        sr.sr_cdemo_sk,
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_fee,
        sr.sr_return_quantity,
        sr.sr_returned_date_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 20220101 AND 20221231
      AND sr.sr_net_loss > 0
)
SELECT
    cd.cd_credit_rating,
    cd.cd_education_status,
    cd.cd_gender,
    COUNT(DISTINCT fr.sr_ticket_number) AS num_returns,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_return_amt) AS avg_return_amount,
    SUM(fr.sr_fee) AS total_fees,
    AVG(fr.sr_return_quantity) AS avg_quantity
FROM filtered_returns fr
JOIN customer_demographics cd
    ON fr.sr_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
  AND cd.cd_education_status = 'College'
  AND cd.cd_gender = 'F'
GROUP BY cd.cd_credit_rating, cd.cd_education_status, cd.cd_gender
HAVING COUNT(*) >= 10
ORDER BY total_net_loss DESC
LIMIT 50
