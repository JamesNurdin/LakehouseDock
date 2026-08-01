WITH item_words AS (
        SELECT i.i_item_sk,
               word
        FROM item i
        CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    ),
    filtered_sales AS (
        SELECT ws.ws_order_number,
               ws.ws_item_sk,
               ws.ws_quantity,
               ws.ws_net_paid,
               i.i_category,
               i.i_brand,
               i.i_product_name,
               sm.sm_code,
               sm.sm_carrier,
               td.t_hour,
               td.t_sub_shift,
               wp.wp_image_count,
               wp.wp_url,
               ws.ws_ship_mode_sk,
               ws.ws_sold_time_sk,
               ws.ws_web_page_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN item_words iw ON i.i_item_sk = iw.i_item_sk
        WHERE sm.sm_code = 'AIR'
          AND td.t_hour BETWEEN 7 AND 9
          AND wp.wp_image_count >= 4
          AND i.i_category = 'Sports'
          AND ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'UPS')
          AND iw.word = 'Premium'
    ),
    high_discount_orders AS (
        SELECT ws_order_number FROM filtered_sales WHERE ws_net_paid > 1000
    ),
    low_discount_orders AS (
        SELECT ws_order_number FROM filtered_sales WHERE ws_net_paid <= 1000
    ),
    orders_excluding_high AS (
        SELECT ws_order_number FROM low_discount_orders
        EXCEPT
        SELECT ws_order_number FROM high_discount_orders
    ),
    union_sales AS (
        SELECT fs.ws_item_sk,
               fs.ws_quantity,
               fs.ws_net_paid,
               i.i_brand,
               sm.sm_carrier,
               td.t_hour,
               wp.wp_image_count
        FROM filtered_sales fs
        JOIN item i ON fs.ws_item_sk = i.i_item_sk
        JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON fs.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
        WHERE fs.ws_order_number IN (SELECT ws_order_number FROM orders_excluding_high)

        UNION DISTINCT

        SELECT fs.ws_item_sk,
               fs.ws_quantity,
               fs.ws_net_paid,
               i.i_brand,
               sm.sm_carrier,
               td.t_hour,
               wp.wp_image_count
        FROM filtered_sales fs
        JOIN item i ON fs.ws_item_sk = i.i_item_sk
        JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON fs.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
        WHERE fs.ws_quantity > 5
    ),
    agg_result AS (
        SELECT us.ws_item_sk,
               i.i_product_name,
               i.i_brand,
               SUM(us.ws_quantity) AS total_qty,
               AVG(us.ws_net_paid) AS avg_net_paid,
               COUNT(DISTINCT us.ws_item_sk) AS distinct_items,
               MAX(us.ws_net_paid) AS max_net_paid,
               MIN(us.ws_net_paid) AS min_net_paid,
               ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(us.ws_quantity) DESC) AS brand_qty_rank,
               (SELECT SUM(ws.ws_net_paid) FROM filtered_sales ws) AS total_net_paid_all
        FROM union_sales us
        JOIN item i ON us.ws_item_sk = i.i_item_sk
        GROUP BY us.ws_item_sk, i.i_product_name, i.i_brand
    )
SELECT *
FROM agg_result
ORDER BY total_qty DESC, avg_net_paid DESC
LIMIT 100
