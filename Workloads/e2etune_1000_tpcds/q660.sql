WITH agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        hd.hd_income_band_sk AS income_band_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_return_time_sk BETWEEN 20200101 AND 20201231
      AND cd.cd_education_status IN ('College', '4 yr Degree')
    GROUP BY cd.cd_gender, cd.cd_education_status, hd.hd_income_band_sk
    HAVING SUM(sr.sr_return_amt_inc_tax) > 1000
)
SELECT
    gender,
    education_status,
    income_band_sk,
    total_return_inc_tax,
    total_net_loss,
    avg_vehicle_cnt,
    distinct_tickets,
    avg_return_qty,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 50
