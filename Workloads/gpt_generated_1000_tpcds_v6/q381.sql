WITH base AS (
    SELECT
        w.w_state,
        td.t_hour,
        (ss.ss_net_profit + ws.ws_net_profit) AS row_profit,
        ss.ss_list_price,
        cd_store.cd_marital_status,
        w.w_zip
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_web
        ON ws.ws_bill_cdemo_sk = cd_web.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cd_store.cd_marital_status = 'M'
      AND w.w_zip IN ('44593', '35709')
      AND ss.ss_list_price > 100
      AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
              AND ws2.ws_net_profit > 5000
        )
),
agg AS (
    SELECT
        w_state,
        t_hour,
        SUM(row_profit) AS total_profit,
        CASE
            WHEN GROUPING(w_state) = 1 AND GROUPING(t_hour) = 0 THEN 'All States'
            WHEN GROUPING(w_state) = 0 AND GROUPING(t_hour) = 1 THEN 'All Hours'
            WHEN GROUPING(w_state) = 1 AND GROUPING(t_hour) = 1 THEN 'Grand Total'
            ELSE 'Detail'
        END AS grouping_level
    FROM base
    GROUP BY ROLLUP (w_state, t_hour)
    HAVING SUM(row_profit) > 0
)
SELECT
    w_state,
    t_hour,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    grouping_level,
    (SELECT AVG(row_profit) FROM base) AS avg_row_profit
FROM agg
ORDER BY total_profit DESC
LIMIT 100
