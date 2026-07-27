WITH filtered_income AS (
    SELECT ib_income_band_sk
    FROM income_band
    WHERE ib_lower_bound >= 50000
)
SELECT
    store_sk,
    hour,
    metric_type,
    total_amount,
    category
FROM (
    SELECT
        ss.ss_store_sk AS store_sk,
        td.t_hour AS hour,
        'sales' AS metric_type,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS category
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN filtered_income fi ON hd.hd_income_band_sk = fi.ib_income_band_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_sub_shift = 'evening'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_quantity > 0
      )
    GROUP BY ss.ss_store_sk, td.t_hour
    UNION ALL
    SELECT
        sr.sr_store_sk AS store_sk,
        td.t_hour AS hour,
        'returns' AS metric_type,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS category
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN filtered_income fi ON hd.hd_income_band_sk = fi.ib_income_band_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_sub_shift = 'evening'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_store_sk, td.t_hour
) combined
ORDER BY total_amount DESC
LIMIT 100
