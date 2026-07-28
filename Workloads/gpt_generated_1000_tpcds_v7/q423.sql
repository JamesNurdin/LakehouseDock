/*
Goal: Compare hourly net revenue from catalog sales with hourly net loss from store returns for customers who are married (M) and belong to households with more than one vehicle, limited to the first half hour of each hour.
The query aggregates each source separately, then combines the results using UNION ALL.
*/
WITH sales_agg AS (
    SELECT
        td.t_hour   AS hour,
        SUM(cs.cs_net_paid)      AS amount,
        'sales'    AS source
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND cd.cd_marital_status = 'M'
      AND td.t_minute BETWEEN 0 AND 30
    GROUP BY td.t_hour
),
returns_agg AS (
    SELECT
        td.t_hour   AS hour,
        SUM(sr.sr_net_loss)      AS amount,
        'returns'  AS source
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE hd.hd_vehicle_count > 1
      AND cd.cd_marital_status = 'M'
      AND td.t_minute BETWEEN 0 AND 30
    GROUP BY td.t_hour
)
SELECT hour, amount, source
FROM sales_agg
UNION ALL
SELECT hour, amount, source
FROM returns_agg
ORDER BY hour, source
