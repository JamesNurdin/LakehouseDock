WITH sales_agg AS (
    SELECT
        td.t_hour AS hour,
        ib.ib_income_band_sk AS income_band_id,
        'sales' AS source,
        SUM(ss.ss_ext_sales_price) AS amount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound >= 60000
    GROUP BY td.t_hour, ib.ib_income_band_sk
),
returns_agg AS (
    SELECT
        td.t_hour AS hour,
        ib.ib_income_band_sk AS income_band_id,
        'returns' AS source,
        SUM(cr.cr_return_amount) AS amount
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound >= 60000
    GROUP BY td.t_hour, ib.ib_income_band_sk
),
combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
)
SELECT
    c.hour,
    c.income_band_id,
    c.source,
    c.amount,
    (SELECT SUM(ss_ext_sales_price) FROM store_sales) AS total_sales_all_time
FROM combined c
ORDER BY c.hour ASC, c.source
LIMIT 100
