WITH daily_sales AS (
    SELECT
        cc.cc_name,
        cc.cc_state,
        ws.web_name,
        ws.web_zip,
        d.d_date,
        SUM(ss.ss_net_profit) AS daily_net_profit,
        SUM(ss.ss_ext_sales_price) AS daily_sales
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND ws.web_zip = '84098'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cc.cc_name, cc.cc_state, ws.web_name, ws.web_zip, d.d_date
    HAVING SUM(ss.ss_net_profit) > 5000
)
SELECT
    ds.cc_name,
    ds.cc_state,
    ds.web_name,
    ds.web_zip,
    ds.d_date,
    ds.daily_net_profit,
    ds.daily_sales,
    ROW_NUMBER() OVER (PARTITION BY ds.cc_name ORDER BY ds.daily_net_profit DESC) AS profit_rank,
    (SELECT AVG(daily_net_profit) FROM daily_sales) AS avg_daily_profit
FROM daily_sales ds
WHERE ds.daily_net_profit > (SELECT AVG(daily_net_profit) FROM daily_sales)
  AND ds.daily_sales > 10000
  AND ds.cc_state IN ('CA', 'TX')
  AND ds.web_name IS NOT NULL
ORDER BY ds.daily_net_profit DESC
LIMIT 100
