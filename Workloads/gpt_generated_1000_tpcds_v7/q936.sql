WITH agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(DISTINCT cr.cr_order_number) AS orders_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(cr.cr_return_amount) AS max_return_amount
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count IN (1, 3, 6)
      AND hd.hd_vehicle_count > 0
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_lower_bound >= 50000
      AND cr.cr_return_ship_cost > 200
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential
)
SELECT
    agg.ib_income_band_sk,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.hd_buy_potential,
    agg.orders_cnt,
    agg.total_return_amount,
    agg.avg_ship_cost,
    agg.min_return_amount,
    agg.max_return_amount,
    SUM(agg.total_return_amount) OVER (
        PARTITION BY agg.ib_income_band_sk
        ORDER BY agg.total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_income
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
