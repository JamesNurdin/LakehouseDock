/* goal: Compare high‑value sales performance between catalog and store channels by aggregating net paid and profit, filtering by business hours, and ranking each channel, while excluding rows below the catalog average net paid. */
WITH catalog_agg AS (
    SELECT
        'catalog' AS src,
        cc.cc_name AS name,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_net_paid_inc_ship > 5000
      AND td.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'AIR'
    GROUP BY cc.cc_name
),
store_agg AS (
    SELECT
        'store' AS src,
        CAST(ss.ss_store_sk AS varchar) AS name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_net_paid > 1000
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returned_time_sk = ss.ss_sold_time_sk
            AND wr.wr_return_amt > 100
      )
    GROUP BY ss.ss_store_sk
)
SELECT
    src,
    name,
    total_net_paid,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY src ORDER BY total_net_paid DESC) AS rn
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) combined
WHERE total_net_paid > (
    SELECT AVG(total_net_paid) FROM catalog_agg
)
ORDER BY src, rn
LIMIT 100
