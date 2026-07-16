WITH sales_summary AS (
    SELECT
        s.s_store_name,
        s.s_state AS store_state,
        sold_dd.d_year AS order_year,
        sold_dd.d_month_seq AS order_month,
        billing_addr.ca_state AS billing_state,
        shipping_addr.ca_state AS shipping_state,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MIN(ws.ws_ext_sales_price) AS min_sales_price,
        MAX(ws.ws_ext_sales_price) AS max_sales_price,
        COUNT(DISTINCT wp.wp_url) AS distinct_pages_visited,
        creation_dd.d_year AS page_creation_year,
        access_dd.d_year AS page_access_year
    FROM web_sales ws
    JOIN date_dim sold_dd
        ON ws.ws_sold_date_sk = sold_dd.d_date_sk
    JOIN date_dim ship_dd
        ON ws.ws_ship_date_sk = ship_dd.d_date_sk
    JOIN customer_address billing_addr
        ON ws.ws_bill_addr_sk = billing_addr.ca_address_sk
    JOIN customer_address shipping_addr
        ON ws.ws_ship_addr_sk = shipping_addr.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim creation_dd
        ON wp.wp_creation_date_sk = creation_dd.d_date_sk
    JOIN date_dim access_dd
        ON wp.wp_access_date_sk = access_dd.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = sold_dd.d_date_sk
    WHERE wp.wp_type = 'product'
      AND s.s_state IS NOT NULL
    GROUP BY
        s.s_store_name,
        s.s_state,
        sold_dd.d_year,
        sold_dd.d_month_seq,
        billing_addr.ca_state,
        shipping_addr.ca_state,
        wp.wp_type,
        creation_dd.d_year,
        access_dd.d_year
)
SELECT
    s_store_name,
    store_state,
    order_year,
    order_month,
    billing_state,
    shipping_state,
    wp_type,
    num_orders,
    total_quantity,
    total_sales,
    total_net_profit,
    avg_sales_price,
    min_sales_price,
    max_sales_price,
    distinct_pages_visited,
    page_creation_year,
    page_access_year,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_summary
ORDER BY total_net_profit DESC
LIMIT 100
