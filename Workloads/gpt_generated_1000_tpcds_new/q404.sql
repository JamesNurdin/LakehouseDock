WITH manager_dates AS (
    SELECT d.d_date_sk,
           d.d_date
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_manager, '^J.*')               -- manager name starts with J
      AND cc.cc_suite_number LIKE '%140%'                 -- suite contains 140
),

web_agg AS (
    SELECT d.d_date,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(*) AS web_sales_cnt,
           CONCAT('Web_', CAST(d.d_date AS varchar)) AS label
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_ext_tax > 20
      AND regexp_like(CAST(ws.ws_ship_addr_sk AS varchar), '^[2-4][0-9]{6}$')
    GROUP BY d.d_date
),

store_agg AS (
    SELECT d.d_date,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS store_ret_cnt,
           CONCAT('Store_', CAST(d.d_date AS varchar)) AS label
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt > 100
      AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_closed_date_sk = d.d_date_sk
              AND cc.cc_manager = 'Jason Brito'
        )
    GROUP BY d.d_date
),

unioned AS (
    SELECT d_date,
           total_net_profit AS metric,
           web_sales_cnt AS cnt,
           label
    FROM web_agg
    UNION
    SELECT d_date,
           total_net_loss AS metric,
           store_ret_cnt AS cnt,
           label
    FROM store_agg
),

intersect_dates AS (
    SELECT d_date FROM web_agg
    INTERSECT
    SELECT d_date FROM store_agg
)
SELECT u.d_date,
       u.metric,
       u.cnt,
       u.label,
       (SELECT COUNT(*) FROM manager_dates md WHERE md.d_date = u.d_date) AS manager_date_count
FROM unioned u
JOIN intersect_dates i ON u.d_date = i.d_date
ORDER BY u.metric DESC
OFFSET 0 LIMIT 100
