WITH joined_data AS (
    SELECT
        sr.sr_hdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE hd.hd_vehicle_count >= 1
      AND hd.hd_vehicle_count <= 4
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000', '>10000')
      AND hd.hd_dep_count BETWEEN 2 AND 8
      AND ib.ib_upper_bound <= 180000
      AND r.r_reason_id <> 'AAAAAAAAABAAAAAA'
), filtered_data AS (
    SELECT *
    FROM joined_data jd
    WHERE NOT EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = jd.sr_reason_sk
          AND r2.r_reason_desc LIKE '%defective%'
    )
)
SELECT
    fd.hd_buy_potential,
    fd.hd_vehicle_count,
    fd.hd_dep_count,
    fd.ib_lower_bound,
    fd.ib_upper_bound,
    fd.r_reason_id,
    SUM(fd.sr_return_amt) AS total_return_amt,
    SUM(fd.sr_return_quantity) AS total_return_qty,
    SUM(fd.sr_net_loss) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY fd.hd_buy_potential ORDER BY SUM(fd.sr_return_amt) DESC) AS rn_by_potential,
    RANK() OVER (ORDER BY SUM(fd.sr_return_amt) DESC) AS rank_overall
FROM filtered_data fd
GROUP BY
    fd.hd_buy_potential,
    fd.hd_vehicle_count,
    fd.hd_dep_count,
    fd.ib_lower_bound,
    fd.ib_upper_bound,
    fd.r_reason_id
HAVING SUM(fd.sr_return_amt) > 1000
ORDER BY rank_overall, total_return_amt DESC
LIMIT 100
