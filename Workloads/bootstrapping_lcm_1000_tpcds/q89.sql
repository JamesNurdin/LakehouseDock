WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        sm.sm_type AS ship_mode_type,
        s.s_state AS store_state,
        wp.wp_type AS page_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        MIN(d_wp_creation.d_date) AS earliest_page_creation,
        MAX(d_wp_access.d_date) AS latest_page_access
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        sm.sm_type,
        s.s_state,
        wp.wp_type
)
SELECT
    sold_year,
    sold_month,
    ship_mode_type,
    store_state,
    page_type,
    order_cnt,
    total_sales,
    total_net_profit,
    total_quantity,
    avg_discount,
    distinct_pages,
    earliest_page_creation,
    latest_page_access,
    RANK() OVER (PARTITION BY sold_year, sold_month ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY sold_year, sold_month, sales_rank
LIMIT 100
