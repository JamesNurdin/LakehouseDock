WITH store_agg AS (
    SELECT
        i.i_category AS category,
        t.t_hour AS hour_of_day,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450997
    GROUP BY i.i_category, t.t_hour
),
web_agg AS (
    SELECT
        i.i_category AS category,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_ext_sales_price) AS web_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450997
    GROUP BY i.i_category, t.t_hour
)
SELECT
    COALESCE(s.category, w.category) AS category,
    COALESCE(s.hour_of_day, w.hour_of_day) AS hour_of_day,
    COALESCE(s.store_sales, 0) AS store_sales,
    COALESCE(w.web_sales, 0) AS web_sales,
    COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales,
    COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit,
    ROUND(
        (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) /
        NULLIF(COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0), 0) * 100,
        2
    ) AS profit_margin_percent,
    RANK() OVER (ORDER BY (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) DESC) AS profit_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.category = w.category
   AND s.hour_of_day = w.hour_of_day
WHERE (COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0)) > 10000
ORDER BY profit_rank
LIMIT 20
