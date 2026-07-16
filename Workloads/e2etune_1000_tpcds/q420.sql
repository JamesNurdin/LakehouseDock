WITH returns_by_demo AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        sr.sr_returned_date_sk,
        hd.hd_income_band_sk AS hd_income_band_sk,
        hd.hd_vehicle_count AS hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451653 AND 2452688
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
),
aggregated AS (
    SELECT
        hd_income_band_sk,
        hd_vehicle_count,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_net_loss) AS avg_net_loss,
        SUM(sr_return_quantity) AS total_quantity
    FROM returns_by_demo
    GROUP BY hd_income_band_sk, hd_vehicle_count
    HAVING COUNT(*) > 5
)
SELECT
    hd_income_band_sk,
    hd_vehicle_count,
    return_count,
    total_return_amount,
    avg_net_loss,
    total_quantity,
    DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
