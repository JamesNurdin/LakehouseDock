WITH sales_by_item AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        w.w_warehouse_name,
        t.t_am_pm,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_ship_cost,
        ws.ws_order_number,
        concat(i.i_brand, '-', i.i_category) AS brand_category,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_code,
        substring(i.i_product_name, 1, 3) AS prod_prefix,
        length(i.i_product_name) AS prod_name_len
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '^[A-Z]{3}[0-9]{2}$')
      AND w.w_country = 'United States'
      AND w.w_warehouse_name LIKE '%Warehouse%'
      AND t.t_am_pm = 'PM'
)
SELECT
    brand_category,
    COUNT(DISTINCT i_item_sk) AS distinct_items,
    SUM(ws_net_paid_inc_ship) AS total_sales,
    AVG(ws_ext_ship_cost) AS avg_ship_cost,
    MAX(prod_name_len) AS max_name_len,
    ROW_NUMBER() OVER (PARTITION BY brand_category ORDER BY SUM(ws_net_paid_inc_ship) DESC) AS brand_rank
FROM sales_by_item
GROUP BY brand_category
HAVING SUM(ws_net_paid_inc_ship) > 10000
ORDER BY total_sales DESC
LIMIT 100
