WITH hd_income AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
store_agg AS (
    SELECT td.t_hour AS hour,
           hi.ib_income_band_sk AS income_band,
           SUM(ss.ss_net_paid) AS total_net_paid,
           'store' AS source,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN hd_income hi
        ON ss.ss_hdemo_sk = hi.hd_demo_sk
    WHERE ss.ss_net_paid > 1000
      AND td.t_hour BETWEEN 9 AND 20
    GROUP BY td.t_hour, hi.ib_income_band_sk
),
web_agg AS (
    SELECT td.t_hour AS hour,
           hi.ib_income_band_sk AS income_band,
           SUM(ws.ws_net_paid) AS total_net_paid,
           'web' AS source,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN hd_income hi
        ON ws.ws_bill_hdemo_sk = hi.hd_demo_sk
    WHERE ws.ws_net_paid > 1000
      AND td.t_hour BETWEEN 9 AND 20
    GROUP BY td.t_hour, hi.ib_income_band_sk
),
combined AS (
    SELECT hour,
           income_band,
           total_net_paid,
           source,
           distinct_customers
    FROM store_agg
    UNION ALL
    SELECT hour,
           income_band,
           total_net_paid,
           source,
           distinct_customers
    FROM web_agg
)
SELECT combined.hour,
       combined.income_band,
       SUM(DISTINCT combined.total_net_paid) AS sum_distinct_total_net_paid,
       COUNT(DISTINCT combined.source) AS distinct_source_count
FROM combined
GROUP BY combined.hour, combined.income_band
ORDER BY combined.hour, combined.income_band
LIMIT 100
