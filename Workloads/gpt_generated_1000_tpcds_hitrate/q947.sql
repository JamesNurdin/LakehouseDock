WITH
    price_groups AS (
        SELECT 'Low'    AS grp, CAST(0 AS decimal(12,2))      AS min_price, CAST(2000 AS decimal(12,2))   AS max_price
        UNION ALL
        SELECT 'Medium' AS grp, CAST(2000 AS decimal(12,2))   AS min_price, CAST(5000 AS decimal(12,2))   AS max_price
        UNION ALL
        SELECT 'High'   AS grp, CAST(5000 AS decimal(12,2))   AS min_price, CAST(100000 AS decimal(12,2)) AS max_price
    ),
    filtered_sales AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_ext_list_price,
            ws.ws_quantity,
            ws.ws_net_profit,
            t.t_shift,
            t.t_sub_shift,
            i.i_category,
            i.i_brand,
            i.i_product_name,
            CASE WHEN ws.ws_ext_sales_price > 5000 THEN 'Large' ELSE 'Small' END AS sale_size
        FROM web_sales ws
        INNER JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        INNER JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        WHERE t.t_shift = 'first'
          AND t.t_sub_shift = 'morning'
          AND i.i_category = 'Electronics'
          AND ws.ws_ext_list_price > 1000
          AND ws.ws_quantity > 0
    )
SELECT
    fs.ws_sold_date_sk,
    fs.t_shift,
    fs.t_sub_shift,
    fs.i_category,
    fs.i_brand,
    fs.i_product_name,
    fs.ws_ext_sales_price,
    fs.ws_quantity,
    fs.sale_size,
    pg.grp AS price_group,
    ROW_NUMBER() OVER (PARTITION BY fs.i_category ORDER BY fs.ws_ext_sales_price DESC) AS prod_rank,
    SUM(fs.ws_ext_sales_price) OVER (PARTITION BY pg.grp) AS grp_total_sales
FROM filtered_sales fs
CROSS JOIN price_groups pg
WHERE fs.ws_ext_sales_price BETWEEN pg.min_price AND pg.max_price
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = fs.ws_order_number
          AND ws2.ws_sold_date_sk > fs.ws_sold_date_sk
    )
ORDER BY prod_rank, price_group
LIMIT 100
