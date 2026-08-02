WITH returns_demo AS (
    SELECT
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN sr.sr_net_loss > 500 THEN 'high_loss'
            ELSE 'low_loss'
        END AS loss_category
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_ship_cost > 50
)
SELECT hd_demo_key
FROM (
    SELECT DISTINCT rd.sr_hdemo_sk AS hd_demo_key
    FROM returns_demo rd
    WHERE rd.hd_vehicle_count >= 2
      AND rd.loss_category = 'high_loss'
    INTERSECT
    SELECT DISTINCT rd.sr_hdemo_sk AS hd_demo_key
    FROM returns_demo rd
    WHERE rd.ib_lower_bound >= 100000
      AND rd.sr_return_amt > 200
) t
ORDER BY hd_demo_key
LIMIT 100
