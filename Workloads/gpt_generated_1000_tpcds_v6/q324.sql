WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
        AND sm.sm_carrier = 'UPS'
        AND c.c_birth_country = 'United States'
        AND ca.ca_gmt_offset = -5.00
        AND ws.ws_net_paid_inc_tax > 500
        AND ws.ws_quantity >= 2
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk
)
SELECT
    wsite.web_name,
    sm.sm_type,
    agg.total_sales,
    agg.avg_sales_price,
    agg.order_cnt,
    agg.total_net_paid_inc_tax
FROM sales_agg agg
JOIN ship_mode sm
    ON agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite
    ON agg.ws_web_site_sk = wsite.web_site_sk
WHERE agg.total_sales > 10000
ORDER BY agg.total_sales DESC
LIMIT 100
