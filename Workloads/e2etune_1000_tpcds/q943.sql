WITH store_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           ss.ss_item_sk,
           SUM(ss.ss_net_profit) AS net_profit,
           COUNT(DISTINCT ss.ss_customer_sk) AS customer_cnt,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND d.d_month_seq BETWEEN 0 AND 2
      AND d.d_holiday = 'N'
      AND t.t_shift = 'Day'
    GROUP BY d.d_year, d.d_month_seq, ss.ss_item_sk
),
web_sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           ws.ws_item_sk AS ss_item_sk,
           SUM(ws.ws_net_profit) AS net_profit,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_cnt,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND d.d_month_seq BETWEEN 0 AND 2
      AND d.d_holiday = 'N'
      AND t.t_shift = 'Day'
    GROUP BY d.d_year, d.d_month_seq, ws.ws_item_sk
)
SELECT agg.d_year,
       agg.d_month_seq,
       agg.ss_item_sk AS item_sk,
       SUM(CASE WHEN agg.channel = 'store' THEN agg.net_profit ELSE 0 END) AS store_net_profit,
       SUM(CASE WHEN agg.channel = 'web' THEN agg.net_profit ELSE 0 END) AS web_net_profit,
       SUM(agg.net_profit) AS total_net_profit,
       SUM(CASE WHEN agg.channel = 'store' THEN agg.customer_cnt ELSE 0 END) AS store_customer_cnt,
       SUM(CASE WHEN agg.channel = 'web' THEN agg.customer_cnt ELSE 0 END) AS web_customer_cnt,
       (SUM(CASE WHEN agg.channel = 'store' THEN agg.net_profit ELSE 0 END) /
        NULLIF(SUM(CASE WHEN agg.channel = 'web' THEN agg.net_profit ELSE 0 END), 0)) AS profit_ratio
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) agg
GROUP BY agg.d_year, agg.d_month_seq, agg.ss_item_sk
HAVING SUM(agg.net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
