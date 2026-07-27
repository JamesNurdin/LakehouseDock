WITH returns_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_class,
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt) AS sum_return_amt,
        SUM(sr.sr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_return_amt > 10
      AND sr.sr_return_tax BETWEEN 0 AND 5
      AND i.i_current_price BETWEEN 5 AND 100
      AND ib.ib_upper_bound <= 200000
      AND hd.hd_vehicle_count >= 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, i.i_class, hd.hd_buy_potential
    HAVING SUM(sr.sr_return_amt) > 20
)
SELECT
    ra.ib_income_band_sk,
    ra.ib_lower_bound,
    ra.ib_upper_bound,
    ra.i_class,
    ra.hd_buy_potential,
    ra.sum_return_amt,
    ra.sum_net_loss,
    ra.cnt_returns,
    (
        SELECT MAX(ib2.ib_upper_bound)
        FROM income_band ib2
        WHERE ib2.ib_lower_bound < ra.ib_lower_bound
    ) AS max_upper_for_lower,
    SUM(ra.sum_return_amt) OVER (
        PARTITION BY ra.i_class
        ORDER BY ra.ib_lower_bound
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_class
FROM returns_agg ra
WHERE EXISTS (
    SELECT 1
    FROM item i2
    WHERE i2.i_class = ra.i_class
      AND i2.i_current_price > 20
)
ORDER BY cum_return_by_class DESC
LIMIT 100
