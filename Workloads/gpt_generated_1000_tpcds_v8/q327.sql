WITH sampled_sales AS (
    SELECT *
    FROM tpcds.web_sales TABLESAMPLE BERNOULLI (10)
),

full_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ext_ship_cost,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        i.i_color,
        i.i_size,
        i.i_product_name,
        i.i_wholesale_cost,
        w.web_name,
        w.web_manager
    FROM sampled_sales ws
    FULL OUTER JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE (i.i_color IS NOT NULL)
      AND (regexp_like(i.i_color, '(purple|royal)') OR i.i_color LIKE '%tan%')
      AND i.i_wholesale_cost > (
          SELECT AVG(i2.i_wholesale_cost)
          FROM tpcds.item i2
          WHERE i2.i_manufact = i.i_manufact
      )
),

aggregated AS (
    SELECT
        web_name,
        sm_carrier,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_ship_cost) AS total_ship_cost,
        AVG(ws_quantity) AS avg_quantity,
        CONCAT(i_color, '-', i_size) AS color_size,
        regexp_extract(i_product_name, '(\\w+)', 1) AS product_first_word
    FROM full_joined
    GROUP BY web_name, sm_carrier, i_color, i_size, i_product_name
    HAVING SUM(ws_ext_sales_price) > 10000
)

SELECT
    web_name,
    sm_carrier,
    distinct_orders,
    total_sales,
    total_ship_cost,
    avg_quantity,
    color_size,
    product_first_word
FROM aggregated
WHERE product_first_word IS NOT NULL
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
