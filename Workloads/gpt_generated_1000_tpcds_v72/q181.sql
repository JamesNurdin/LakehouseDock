WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
)
SELECT transaction_type,
       ship_mode_id,
       sub_shift,
       total_amount,
       total_profit,
       profit_category
FROM (
    SELECT
        'sale' AS transaction_type,
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_sub_shift AS sub_shift,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > (SELECT avg_profit FROM avg_profit)
            THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_second > 5
      AND sm.sm_code = 'AIR'
    GROUP BY sm.sm_ship_mode_id, td.t_sub_shift

    UNION ALL

    SELECT
        'return' AS transaction_type,
        CAST(NULL AS VARCHAR) AS ship_mode_id,
        td.t_sub_shift AS sub_shift,
        SUM(sr.sr_return_amt) AS total_amount,
        SUM(sr.sr_net_loss) AS total_profit,
        CASE WHEN SUM(sr.sr_return_amt) > 1000
            THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_sub_shift IN ('morning', 'afternoon')
    GROUP BY td.t_sub_shift
) AS combined
ORDER BY transaction_type, total_amount DESC
LIMIT 100
