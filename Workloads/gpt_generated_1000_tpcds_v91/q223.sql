WITH sampled_web_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_hdemo_sk,
        wr_reason_sk,
        wr_return_amt,
        wr_return_tax,
        wr_return_ship_cost,
        wr_refunded_cash
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
),
base_join AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        d.d_year,
        d.d_date,
        i.i_brand,
        i.i_wholesale_cost,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        r.r_reason_desc
    FROM sampled_web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '1999-10-28' AND DATE '2001-10-27'
      AND i.i_wholesale_cost > 5.00
      AND hd.hd_income_band_sk IN (8, 15)
      AND hd.hd_buy_potential = '1001-5000'
)
SELECT
    d_year,
    i_brand,
    hd_buy_potential,
    vehicle_category,
    return_cnt,
    total_return_amount,
    avg_return_tax,
    min_ship_cost,
    max_refunded_cash,
    high_vehicle_return_amount
FROM (
    SELECT
        d_year,
        i_brand,
        hd_buy_potential,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_tax) AS avg_return_tax,
        MIN(wr_return_ship_cost) AS min_ship_cost,
        MAX(wr_refunded_cash) AS max_refunded_cash,
        SUM(CASE WHEN hd_vehicle_count > 2 THEN wr_return_amt ELSE 0 END) AS high_vehicle_return_amount
    FROM base_join
    WHERE r_reason_desc = 'Damaged'
    GROUP BY
        d_year,
        i_brand,
        hd_buy_potential,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
    UNION ALL
    SELECT
        d_year,
        i_brand,
        hd_buy_potential,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_tax) AS avg_return_tax,
        MIN(wr_return_ship_cost) AS min_ship_cost,
        MAX(wr_refunded_cash) AS max_refunded_cash,
        SUM(CASE WHEN hd_vehicle_count > 2 THEN wr_return_amt ELSE 0 END) AS high_vehicle_return_amount
    FROM base_join
    WHERE r_reason_desc = 'Not as described'
    GROUP BY
        d_year,
        i_brand,
        hd_buy_potential,
        CASE WHEN hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
) final
ORDER BY total_return_amount DESC
LIMIT 100
