WITH sales_time AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        td.t_meal_time,
        td.t_hour,
        td.t_minute
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_ext_sales_price > 500
)

SELECT
    st.t_meal_time,
    st.t_hour,
    st.ws_item_sk,
    SUM(st.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT st.ws_order_number) AS distinct_orders,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = st.ws_item_sk
    ) AS avg_net_profit_per_item
FROM sales_time st
WHERE st.t_meal_time = 'breakfast'
  AND st.ws_item_sk IN (
        SELECT ws3.ws_item_sk
        FROM web_sales ws3
        GROUP BY ws3.ws_item_sk
        HAVING SUM(ws3.ws_quantity) > 2000
    )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws4
        WHERE ws4.ws_item_sk = st.ws_item_sk
          AND ws4.ws_quantity > 5
    )
GROUP BY st.t_meal_time, st.t_hour, st.ws_item_sk

UNION ALL

SELECT
    st.t_meal_time,
    st.t_hour,
    st.ws_item_sk,
    SUM(st.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT st.ws_order_number) AS distinct_orders,
    (
        SELECT AVG(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = st.ws_item_sk
    ) AS avg_net_profit_per_item
FROM sales_time st
WHERE st.t_meal_time = 'dinner'
  AND st.ws_item_sk IN (
        SELECT ws3.ws_item_sk
        FROM web_sales ws3
        GROUP BY ws3.ws_item_sk
        HAVING SUM(ws3.ws_quantity) > 2000
    )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws4
        WHERE ws4.ws_item_sk = st.ws_item_sk
          AND ws4.ws_quantity > 5
    )
GROUP BY st.t_meal_time, st.t_hour, st.ws_item_sk

ORDER BY total_sales DESC
LIMIT 100
