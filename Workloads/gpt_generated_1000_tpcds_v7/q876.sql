WITH sales_ship AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_ship_hdemo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
filtered_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_date_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        hd.hd_vehicle_count,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        ws.web_manager,
        ws.web_name
    FROM sales_ship cs
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws ON ws.web_open_date_sk = cs.cs_ship_date_sk
    WHERE hd.hd_vehicle_count > 0
      AND regexp_like(w.w_city, '^A.*')
      AND ws.web_manager LIKE '%James%'
)
SELECT
    fs.w_warehouse_id,
    fs.w_warehouse_name,
    fs.w_city,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    SUM(fs.cs_net_profit) AS total_net_profit,
    regexp_extract(fs.web_name, '([A-Za-z]+)', 1) AS first_word_web_name,
    concat(fs.w_warehouse_name, ' - ', fs.w_city) AS warehouse_full_desc,
    length(fs.web_manager) AS manager_name_len,
    substring(fs.web_manager, 1, 5) AS manager_prefix
FROM filtered_sales fs
GROUP BY
    fs.w_warehouse_id,
    fs.w_warehouse_name,
    fs.w_city,
    fs.web_name,
    fs.web_manager
HAVING SUM(fs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
