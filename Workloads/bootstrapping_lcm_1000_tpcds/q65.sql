WITH aggregated AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_current_month,
        sm.sm_type,
        s.s_state,
        s.s_tax_percentage,
        s.s_floor_space,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_price_per_item,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        AVG(wp.wp_image_count) AS avg_images_per_page
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE ws.ws_net_profit > 0
      AND d_ship.d_year = d_sold.d_year
      AND d_ship.d_month_seq = d_sold.d_month_seq
      AND d_page_creation.d_date <= d_sold.d_date
      AND d_page_access.d_date >= d_sold.d_date
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_current_month,
        sm.sm_type,
        s.s_state,
        s.s_tax_percentage,
        s.s_floor_space
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.d_current_month,
    a.sm_type,
    a.s_state,
    a.s_tax_percentage,
    a.num_orders,
    a.total_quantity,
    a.total_sales,
    a.total_net_profit,
    a.avg_discount,
    a.avg_price_per_item,
    a.total_net_profit / NULLIF(a.s_floor_space, 0) AS profit_per_sqft,
    a.distinct_pages,
    a.avg_images_per_page,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_profit DESC) AS profit_rank_in_month
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
