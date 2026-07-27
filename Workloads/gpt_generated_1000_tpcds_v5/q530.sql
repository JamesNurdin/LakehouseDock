WITH avg_return AS (
    SELECT avg(wr_return_amt) AS avg_amt
    FROM web_returns
)
SELECT DISTINCT
    combined.hd_buy_potential,
    combined.cd_credit_rating,
    COUNT(*) OVER (PARTITION BY combined.hd_buy_potential, combined.cd_credit_rating) AS return_cnt
FROM (
    SELECT DISTINCT
        wr.wr_return_amt,
        cd.cd_credit_rating,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count > 0
      AND wr.wr_return_amt > (SELECT avg_amt FROM avg_return)

    UNION ALL

    SELECT DISTINCT
        wr.wr_return_amt,
        cd.cd_credit_rating,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND hd.hd_income_band_sk IN (1, 8, 11)
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_return_quantity > 5
            AND wr2.wr_return_amt = wr.wr_return_amt
      )
) AS combined
ORDER BY combined.hd_buy_potential, combined.cd_credit_rating
LIMIT 100
