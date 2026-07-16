WITH aggregated AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        ds_sold.d_year AS sold_year,
        ds_sold.d_month_seq AS sold_month_seq,
        ds_ship.d_year AS ship_year,
        ds_ship.d_month_seq AS ship_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        wp.wp_url,
        wp.wp_type,
        ds_wp_creation.d_year AS wp_creation_year,
        ds_wp_access.d_year AS wp_access_year,
        ds_cc_open.d_year AS cc_open_year,
        ds_cc_closed.d_year AS cc_closed_year
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim ds_sold
        ON cs.cs_sold_date_sk = ds_sold.d_date_sk
    JOIN date_dim ds_ship
        ON cs.cs_ship_date_sk = ds_ship.d_date_sk
    JOIN date_dim ds_cc_closed
        ON cc.cc_closed_date_sk = ds_cc_closed.d_date_sk
    JOIN date_dim ds_cc_open
        ON cc.cc_open_date_sk = ds_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = ds_cc_closed.d_date_sk
    JOIN date_dim ds_wp_creation
        ON cs.cs_sold_date_sk = ds_wp_creation.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = ds_wp_creation.d_date_sk
    JOIN date_dim ds_wp_access
        ON wp.wp_access_date_sk = ds_wp_access.d_date_sk
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        ds_sold.d_year,
        ds_sold.d_month_seq,
        ds_ship.d_year,
        ds_ship.d_month_seq,
        wp.wp_url,
        wp.wp_type,
        ds_wp_creation.d_year,
        ds_wp_access.d_year,
        ds_cc_open.d_year,
        ds_cc_closed.d_year
)
SELECT
    cc_call_center_id,
    cc_city,
    cc_state,
    s_store_id,
    s_store_name,
    store_city,
    sold_year,
    sold_month_seq,
    ship_year,
    ship_month_seq,
    total_net_paid,
    total_quantity,
    order_count,
    wp_url,
    wp_type,
    wp_creation_year,
    wp_access_year,
    cc_open_year,
    cc_closed_year,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_net_paid DESC) AS rank_in_year
FROM aggregated
ORDER BY sold_year, total_net_paid DESC
LIMIT 100
