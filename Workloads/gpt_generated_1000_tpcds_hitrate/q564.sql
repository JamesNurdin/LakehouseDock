WITH max_net_paid AS (
    SELECT MAX(cs_net_paid_inc_tax) AS mx FROM catalog_sales
),
catalog_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        td.t_hour AS hour_of_day,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_flag,
        COUNT(DISTINCT letter) AS distinct_letters
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(split(w.w_warehouse_id, '')) AS t(letter)
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid_inc_tax > (SELECT mx FROM max_net_paid)
      AND w.w_country = 'United States'
      AND w.w_city = 'New York'
      AND cs.cs_list_price BETWEEN 50 AND 300
      AND cs.cs_ship_cdemo_sk IN (775031, 400608)
    GROUP BY w.w_warehouse_id, td.t_hour
),
web_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        td.t_hour AS hour_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_flag,
        COUNT(DISTINCT letter) AS distinct_letters
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(split(w.w_warehouse_id, '')) AS t(letter)
    WHERE ws.ws_quantity > 3
      AND ws.ws_net_paid_inc_ship_tax > (SELECT mx FROM max_net_paid)
      AND w.w_state = 'CA'
      AND ws.ws_list_price BETWEEN 100 AND 300
      AND ws.ws_ship_cdemo_sk IN (1910424)
    GROUP BY w.w_warehouse_id, td.t_hour
),
unioned AS (
    SELECT * FROM catalog_agg
    UNION DISTINCT
    SELECT * FROM web_agg
)
SELECT
    warehouse_id,
    hour_of_day,
    SUM(total_sales) AS total_sales_all,
    AVG(avg_discount) AS avg_discount_all,
    SUM(order_cnt) AS total_orders,
    SUM(distinct_letters) AS total_distinct_letters,
    CASE WHEN SUM(total_sales) > 20000 THEN 'VERY HIGH' ELSE 'NORMAL' END AS overall_flag
FROM unioned
GROUP BY warehouse_id, hour_of_day
ORDER BY total_sales_all DESC
LIMIT 100
