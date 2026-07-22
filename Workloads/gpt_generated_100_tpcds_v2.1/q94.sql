WITH time_info AS (
    SELECT t_time_sk, t_hour, t_shift
    FROM time_dim
    WHERE t_hour BETWEEN 8 AND 20
),
catalog_agg AS (
    SELECT
        'Catalog' AS sales_channel,
        ti.t_hour AS hour,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM time_info ti
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = ti.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
      AND cs.cs_ext_discount_amt > 1000
    GROUP BY ti.t_hour
),
web_agg AS (
    SELECT
        'Web' AS sales_channel,
        ti.t_hour AS hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM time_info ti
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = ti.t_time_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
      AND ws.ws_ext_discount_amt > 1000
    GROUP BY ti.t_hour
)
SELECT
    sales_channel,
    hour,
    total_net_paid,
    total_net_profit
FROM catalog_agg
UNION ALL
SELECT
    sales_channel,
    hour,
    total_net_paid,
    total_net_profit
FROM web_agg
ORDER BY hour, sales_channel
LIMIT 100
