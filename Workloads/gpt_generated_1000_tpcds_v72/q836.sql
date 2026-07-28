WITH
    -- scalar subquery used in the first SELECT
    high_income_upper AS (
        SELECT ib_upper_bound
        FROM income_band
        WHERE ib_income_band_sk = 9
    )
SELECT
    hour,
    source,
    total_amount,
    rank_in_hour
FROM (
    SELECT
        t.t_hour AS hour,
        'web' AS source,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY t.t_hour
            ORDER BY SUM(ws.ws_ext_sales_price) DESC
        ) AS rank_in_hour
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '5001-10000'
      AND ib.ib_upper_bound = (SELECT ib_upper_bound FROM high_income_upper)
    GROUP BY t.t_hour
    UNION ALL
    SELECT
        t.t_hour AS hour,
        'store' AS source,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY t.t_hour
            ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC
        ) AS rank_in_hour
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound > 100000
    GROUP BY t.t_hour
) AS combined
ORDER BY hour, total_amount DESC
LIMIT 100
