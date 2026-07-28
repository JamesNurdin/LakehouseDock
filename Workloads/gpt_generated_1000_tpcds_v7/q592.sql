WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_fee,
        wr.wr_reversed_charge,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_fee > 20
      AND wr.wr_return_quantity BETWEEN 1 AND 3
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    SUM(fr.wr_return_amt) AS total_return_amt,
    AVG(fr.wr_fee) AS avg_fee,
    COUNT(*) AS return_count,
    MIN(fr.wr_return_tax) AS min_tax,
    MAX(fr.wr_return_tax) AS max_tax
FROM filtered_returns fr
JOIN customer_demographics cd
  ON fr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_dep_college_count >= 1
  AND hd.hd_vehicle_count >= 0
  AND hd.hd_buy_potential = '>10000'
GROUP BY cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
ORDER BY total_return_amt DESC
LIMIT 100
