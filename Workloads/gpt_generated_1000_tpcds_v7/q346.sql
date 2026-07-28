WITH store_agg AS (
    SELECT
        'store' AS sales_channel,
        td.t_hour,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
web_agg AS (
    SELECT
        'web' AS sales_channel,
        td.t_hour,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY td.t_hour
)
SELECT sales_channel,
       t_hour,
       total_sales
FROM store_agg
UNION ALL
SELECT sales_channel,
       t_hour,
       total_sales
FROM web_agg
ORDER BY t_hour,
         sales_channel
