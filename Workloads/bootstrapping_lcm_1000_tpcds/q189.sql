WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wsite.web_site_id,
        wsite.web_name,
        wsite.web_city,
        wsite.web_state,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        sold_date.d_year AS sold_year,
        sold_date.d_month_seq AS sold_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim sold_date
        ON ws.ws_sold_date_sk = sold_date.d_date_sk
    JOIN date_dim ship_date
        ON ws.ws_ship_date_sk = ship_date.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim page_creation_date
        ON wp.wp_creation_date_sk = page_creation_date.d_date_sk
    JOIN date_dim page_access_date
        ON wp.wp_access_date_sk = page_access_date.d_date_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim site_open_date
        ON wsite.web_open_date_sk = site_open_date.d_date_sk
    JOIN date_dim site_close_date
        ON wsite.web_close_date_sk = site_close_date.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = site_close_date.d_date_sk
    WHERE sold_date.d_year >= 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wsite.web_site_id,
        wsite.web_name,
        wsite.web_city,
        wsite.web_state,
        wp.wp_web_page_id,
        wp.wp_url,
        wp.wp_type,
        sold_date.d_year,
        sold_date.d_month_seq
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.store_city,
    a.store_state,
    a.web_site_id,
    a.web_name,
    a.web_city,
    a.web_state,
    a.wp_web_page_id,
    a.wp_url,
    a.wp_type,
    a.sold_year,
    a.sold_month_seq,
    a.total_sales,
    a.total_discount,
    a.total_profit,
    a.distinct_orders,
    a.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS sales_rank_by_store
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
