-- Total net profit, sales and quantity per item category and hour of day across store, catalog, and web channels
WITH catalog AS (
    SELECT
        i.i_category AS category,
        td.t_hour   AS hour_of_day,
        SUM(cs.cs_net_profit)          AS catalog_profit,
        SUM(cs.cs_ext_sales_price)     AS catalog_sales,
        SUM(cs.cs_quantity)            AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, td.t_hour
),
store AS (
    SELECT
        i.i_category AS category,
        td.t_hour   AS hour_of_day,
        SUM(ss.ss_net_profit)          AS store_profit,
        SUM(ss.ss_ext_sales_price)     AS store_sales,
        SUM(ss.ss_quantity)            AS store_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, td.t_hour
),
web AS (
    SELECT
        i.i_category AS category,
        td.t_hour   AS hour_of_day,
        SUM(ws.ws_net_profit)          AS web_profit,
        SUM(ws.ws_ext_sales_price)     AS web_sales,
        SUM(ws.ws_quantity)            AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, td.t_hour
)
SELECT
    COALESCE(c.category, s.category, w.category)               AS category,
    COALESCE(c.hour_of_day, s.hour_of_day, w.hour_of_day)     AS hour_of_day,
    COALESCE(c.catalog_profit, 0) + COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0) AS total_net_profit,
    COALESCE(c.catalog_sales, 0) + COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0)   AS total_sales,
    COALESCE(c.catalog_quantity, 0) + COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
FROM catalog c
FULL OUTER JOIN store s
    ON c.category = s.category AND c.hour_of_day = s.hour_of_day
FULL OUTER JOIN web w
    ON COALESCE(c.category, s.category) = w.category
   AND COALESCE(c.hour_of_day, s.hour_of_day) = w.hour_of_day
ORDER BY total_net_profit DESC
LIMIT 20
