WITH fo AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_ship_cost,
        sr.sr_reversed_charge
    FROM household_demographics hd
    FULL OUTER JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    sr_return_amt,
    sr_return_quantity,
    total_return_amt,
    income_band_rank
FROM (
    SELECT
        fo.*, 
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_hdemo_sk = fo.hd_demo_sk) AS total_return_amt,
        RANK() OVER (PARTITION BY fo.hd_income_band_sk ORDER BY fo.sr_return_amt DESC) AS income_band_rank
    FROM fo
    WHERE fo.hd_buy_potential = '5001-10000'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr3
          WHERE sr3.sr_hdemo_sk = fo.hd_demo_sk
            AND sr3.sr_return_quantity > 20
      )
) q1
UNION ALL
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    sr_return_amt,
    sr_return_quantity,
    total_return_amt,
    income_band_rank
FROM (
    SELECT
        fo.*, 
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_hdemo_sk = fo.hd_demo_sk) AS total_return_amt,
        RANK() OVER (PARTITION BY fo.hd_income_band_sk ORDER BY fo.sr_return_amt DESC) AS income_band_rank
    FROM fo
    WHERE fo.hd_buy_potential = '>10000'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr3
          WHERE sr3.sr_hdemo_sk = fo.hd_demo_sk
            AND sr3.sr_return_quantity > 20
      )
) q2
ORDER BY hd_income_band_sk, income_band_rank
LIMIT 100
