WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        w.w_warehouse_name,
        wp.wp_type,
        r.r_reason_desc,
        t.t_hour,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_net_paid ELSE 0 END) AS high_qty_net,
        MIN(ws.ws_sold_date_sk) AS first_sale_date_sk,
        MAX(ws.ws_sold_date_sk) AS last_sale_date_sk
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND ca.ca_country = 'United States'
        AND w.w_state = 'CA'
        AND wp.wp_max_ad_count >= 2
        AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2452000
        AND ws.ws_net_paid > 1000
    GROUP BY
        c.c_customer_id,
        ca.ca_state,
        w.w_warehouse_name,
        wp.wp_type,
        r.r_reason_desc,
        t.t_hour
)
SELECT
    c_customer_id,
    ca_state,
    w_warehouse_name,
    wp_type,
    r_reason_desc,
    t_hour,
    orders,
    total_net_paid,
    avg_discount,
    high_qty_net,
    first_sale_date_sk,
    last_sale_date_sk
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
