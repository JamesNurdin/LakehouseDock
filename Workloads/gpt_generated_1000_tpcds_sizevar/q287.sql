WITH web_agg AS (
    SELECT
        wr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        AVG(wr_return_tax) AS avg_wr_return_tax,
        COUNT(*) AS cnt_wr_returns
    FROM web_returns
    WHERE wr_return_ship_cost > 10
      AND wr_reversed_charge < 200
      AND wr_returning_hdemo_sk IN (159, 1870, 656)
      AND wr_return_amt > 50
      AND wr_return_tax BETWEEN 5 AND 150
      AND wr_order_number % 2 = 0
    GROUP BY wr_refunded_hdemo_sk
)
SELECT
    income_band,
    vehicle_count,
    ship_mode,
    total_cr_return_amount,
    total_wr_return_amt,
    total_rows,
    min_return_qty,
    max_return_qty
FROM (
    SELECT
        hd.hd_income_band_sk AS income_band,
        hd.hd_vehicle_count AS vehicle_count,
        cr.cr_ship_mode_sk AS ship_mode,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(wa.sum_wr_return_amt) AS total_wr_return_amt,
        COUNT(*) AS total_rows,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_agg wa
        ON wa.hd_demo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount BETWEEN 100 AND 2000
      AND cr.cr_fee < 50
      AND cr.cr_return_ship_cost > 5
      AND cr.cr_reversed_charge < 1000
      AND hd.hd_income_band_sk IN (5, 7, 9)
      AND hd.hd_dep_count <= 2
    GROUP BY CUBE (hd.hd_income_band_sk, hd.hd_vehicle_count, cr.cr_ship_mode_sk)

    UNION DISTINCT

    SELECT
        hd.hd_income_band_sk AS income_band,
        hd.hd_vehicle_count AS vehicle_count,
        cr.cr_ship_mode_sk AS ship_mode,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(wa.sum_wr_return_amt) AS total_wr_return_amt,
        COUNT(*) AS total_rows,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_agg wa
        ON wa.hd_demo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount BETWEEN 500 AND 1500
      AND cr.cr_fee BETWEEN 10 AND 40
      AND cr.cr_return_ship_cost > 20
      AND cr.cr_reversed_charge BETWEEN 100 AND 800
      AND hd.hd_income_band_sk IN (6, 16)
      AND hd.hd_vehicle_count >= 2
    GROUP BY CUBE (hd.hd_income_band_sk, hd.hd_vehicle_count, cr.cr_ship_mode_sk)
) t
ORDER BY total_cr_return_amount DESC
LIMIT 100
