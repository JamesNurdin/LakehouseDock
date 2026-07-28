WITH sales_agg AS (
    SELECT
        w.w_country AS country,
        w.w_county AS county,
        CASE WHEN ws.ws_list_price > 150 THEN 'High' ELSE 'Low' END AS price_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_list_price > 100                     -- predicate 1: only relatively expensive items
      AND ws.ws_quantity >= 2                        -- predicate 2: at least two units per sale
      AND w.w_country = 'United States'              -- predicate 3: U.S. warehouses only
    GROUP BY
        w.w_country,
        w.w_county,
        CASE WHEN ws.ws_list_price > 150 THEN 'High' ELSE 'Low' END
)
SELECT
    country,
    county,
    price_category,
    SUM(total_sales) AS sum_sales,
    SUM(total_profit) AS sum_profit,
    SUM(order_cnt) AS total_orders,
    AVG(total_profit) AS avg_profit_per_group
FROM sales_agg
GROUP BY GROUPING SETS (
    (country, county, price_category),
    (country, county),
    (country),
    ()
)
HAVING SUM(total_profit) > 5000
ORDER BY sum_sales DESC
LIMIT 100
