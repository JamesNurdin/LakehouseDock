WITH joined_data AS (
    SELECT
        s.s_division_name,
        t.t_hour,
        ss.ss_net_profit,
        ss.ss_quantity,
        inv.inv_quantity_on_hand,
        cd.cd_purchase_estimate,
        COALESCE(cc.cc_name, 'No Call Center') AS call_center_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
),
agg1 AS (
    SELECT
        s_division_name,
        t_hour,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_quantity,
        AVG(cd_purchase_estimate) AS avg_estimate,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY s_division_name, t_hour
)
SELECT
    s_division_name,
    AVG(total_profit) AS avg_hourly_profit,
    SUM(total_quantity) AS total_quantity,
    AVG(avg_estimate) AS avg_purchase_estimate
FROM agg1
GROUP BY s_division_name
HAVING AVG(total_profit) > 10000
ORDER BY avg_hourly_profit DESC
LIMIT 100
