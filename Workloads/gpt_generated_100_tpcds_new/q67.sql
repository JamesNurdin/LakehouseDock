WITH filtered_returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_ship_cost,
        sr.sr_fee,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'S'
      AND cd.cd_education_status = 'College'
      AND cd.cd_dep_employed_count >= 2
      AND cd.cd_dep_college_count <= 3
      AND sr.sr_return_amt > 100
      AND sr.sr_fee > (
          SELECT AVG(sr2.sr_fee)
          FROM store_returns sr2
          WHERE sr2.sr_return_quantity > 5
      )
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(DISTINCT sr_ticket_number) AS num_returns,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt_inc_tax) AS avg_return_inc_tax,
    MIN(sr_return_ship_cost) AS min_ship_cost,
    MAX(sr_fee) AS max_fee
FROM filtered_returns
GROUP BY cd_gender, cd_marital_status, cd_education_status
ORDER BY total_return_amt DESC
LIMIT 100
