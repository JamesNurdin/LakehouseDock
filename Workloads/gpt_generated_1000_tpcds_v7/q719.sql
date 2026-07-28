WITH store_agg AS (
    SELECT
        i.i_item_id,
        td.t_hour AS hour_of_day,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
    GROUP BY i.i_item_id, td.t_hour
),
web_agg AS (
    SELECT
        i.i_item_id,
        td.t_hour AS hour_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
    GROUP BY i.i_item_id, td.t_hour
)
SELECT i_item_id, hour_of_day, total_sales, transaction_count
FROM store_agg
UNION ALL
SELECT i_item_id, hour_of_day, total_sales, transaction_count
FROM web_agg
