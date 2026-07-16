WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk      AS sold_date_sk,
        ws.ws_ship_date_sk      AS ship_date_sk,
        ws.ws_web_page_sk       AS web_page_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit)                AS total_profit,
        COUNT(*)                             AS order_cnt,
        SUM(ws.ws_quantity)                  AS total_quantity
    FROM web_sales ws
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_page_sk
)
SELECT
    d_sold.d_date                AS sold_date,
    d_sold.d_year                AS sold_year,
    d_sold.d_month_seq           AS sold_month_seq,
    d_ship.d_date                AS ship_date,
    d_ship.d_week_seq            AS ship_week_seq,
    wp.wp_url                    AS page_url,
    wp.wp_type                   AS page_type,
    inv.inv_quantity_on_hand    AS inventory_on_hand,
    s.s_store_name               AS store_name,
    s.s_market_desc              AS market_description,
    s.s_country                  AS store_country,
    sb.total_sales,
    sb.total_profit,
    sb.order_cnt,
    sb.total_quantity,
    CASE
        WHEN inv.inv_quantity_on_hand > 0
        THEN CAST(sb.total_quantity AS DOUBLE) / inv.inv_quantity_on_hand
        ELSE NULL
    END                         AS sales_to_inventory_ratio,
    d_creation.d_current_month   AS page_creation_month,
    d_access.d_current_month     AS page_access_month
FROM sales_agg sb
JOIN date_dim d_sold
    ON sb.sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON sb.ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON sb.web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2022
ORDER BY d_sold.d_date DESC
LIMIT 200
