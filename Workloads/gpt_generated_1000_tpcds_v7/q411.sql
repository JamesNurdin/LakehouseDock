WITH returns_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100 AND
        cr.cr_return_ship_cost > 100 AND
        hd.hd_dep_count >= 2 AND
        hd.hd_vehicle_count <= 3 AND
        hd.hd_buy_potential IN ('0-500', '501-1000', '1001-5000') AND
        ib.ib_lower_bound >= 20000
    GROUP BY
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    hd_demo_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    cnt_returns,
    avg_ship_cost,
    RANK() OVER (PARTITION BY ib_lower_bound ORDER BY total_return_amount DESC) AS rank_within_income_band,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS overall_rank
FROM returns_by_demo
WHERE
    total_return_amount > 5000 AND
    cnt_returns >= 5
ORDER BY overall_rank
LIMIT 100
