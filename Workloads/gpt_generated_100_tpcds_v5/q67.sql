WITH base AS (
    SELECT
        cc.cc_state,
        p.p_promo_name,
        d_sales.d_year,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d_sales.d_holiday = 'N'
      AND wp.wp_image_count > 2
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND d_sales.d_year BETWEEN 2000 AND 2002
),
agg AS (
    SELECT
        cc_state,
        p_promo_name,
        d_year,
        ws_net_paid AS net_paid,
        ws_quantity AS quantity,
        ws_order_number AS order_number,
        ws_ext_sales_price
    FROM base
)
SELECT
    cc_state,
    p_promo_name,
    d_year,
    SUM(net_paid) AS total_net_paid,
    AVG(quantity) AS avg_quantity,
    COUNT(DISTINCT order_number) AS distinct_orders,
    (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2002
        )
    ) AS recent_avg_ext_sales_price
FROM agg
GROUP BY GROUPING SETS (
    (cc_state, p_promo_name, d_year),
    (cc_state, p_promo_name),
    (cc_state),
    (p_promo_name),
    ()
)
HAVING SUM(net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
