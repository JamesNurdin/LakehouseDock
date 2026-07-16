WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month_seq,
        wp.wp_type,
        d_creation.d_year AS page_creation_year,
        d_access.d_year AS page_access_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_coupon_amt) AS total_coupon_amount
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE ws.ws_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq,
        wp.wp_type,
        d_creation.d_year,
        d_access.d_year
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    s_city,
    sale_year,
    sale_month_seq,
    ship_year,
    ship_month_seq,
    wp_type,
    page_creation_year,
    page_access_year,
    total_quantity,
    total_sales,
    total_profit,
    avg_discount,
    total_coupon_amount,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
