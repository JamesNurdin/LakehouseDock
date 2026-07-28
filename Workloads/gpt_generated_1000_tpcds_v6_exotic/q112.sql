WITH web_agg AS (
    SELECT
        'WEB' AS channel,
        d.d_year AS d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND ws.ws_ext_wholesale_cost > 3000
    GROUP BY d.d_year
),
store_agg AS (
    SELECT
        'STORE' AS channel,
        d.d_year AS d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND ss.ss_ext_sales_price > 5000
    GROUP BY d.d_year
)
SELECT channel, d_year, total_net_paid, total_net_profit
FROM web_agg
UNION ALL
SELECT channel, d_year, total_net_paid, total_net_profit
FROM store_agg
ORDER BY channel, d_year, total_net_paid DESC
LIMIT 100
