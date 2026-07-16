WITH aggregated AS (
    SELECT
        d_sold.d_year AS sales_year,
        d_sold.d_month_seq AS sales_month_seq,
        d_ship.d_month_seq AS ship_month_seq,
        d_store.d_year AS store_closed_year,
        s.s_store_name,
        s.s_city,
        ws.web_name,
        ws.web_market_manager,
        d_ws_open.d_date AS site_open_date,
        d_ws_close.d_date AS site_close_date,
        COUNT(*) AS total_sales_transactions,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(wp.wp_image_count) AS total_image_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        DATE_DIFF('day', d_ws_open.d_date, d_ws_close.d_date) AS site_open_duration_days
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_store ON cs.cs_sold_date_sk = d_store.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN date_dim d_ws_open ON cs.cs_sold_date_sk = d_ws_open.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN date_dim d_wp_creation ON cs.cs_sold_date_sk = d_wp_creation.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year >= 2000
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_month_seq,
        d_store.d_year,
        s.s_store_name,
        s.s_city,
        ws.web_name,
        ws.web_market_manager,
        d_ws_open.d_date,
        d_ws_close.d_date
)
SELECT
    sales_year,
    sales_month_seq,
    ship_month_seq,
    store_closed_year,
    s_store_name,
    s_city,
    web_name,
    web_market_manager,
    site_open_date,
    site_close_date,
    total_sales_transactions,
    total_net_paid,
    total_net_profit,
    avg_discount,
    total_quantity,
    total_image_count,
    distinct_web_pages,
    site_open_duration_days,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_net_paid DESC) AS sales_rank_by_year
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
