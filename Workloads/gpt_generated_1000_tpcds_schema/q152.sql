WITH billed_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_list_price AS ext_list_price,
        hd.hd_buy_potential AS buy_potential,
        ca.ca_city AS city,
        wp.wp_url AS url,
        site.web_name AS web_name
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND ws.ws_ext_list_price > 2000
      AND ca.ca_gmt_offset = -5.00
      AND site.web_city = 'Springfield'
),
shipped_sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_list_price AS ext_list_price,
        hd.hd_buy_potential AS buy_potential,
        ca.ca_city AS city,
        wp.wp_url AS url,
        site.web_name AS web_name
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE hd.hd_vehicle_count > 0
      AND wp.wp_link_count >= 20
      AND ca.ca_suite_number LIKE 'Suite %'
      AND site.web_mkt_id IN (2, 4, 5)
)
SELECT
    row_number() OVER (ORDER BY order_number) AS row_num,
    order_number,
    ext_list_price,
    buy_potential,
    city,
    url,
    web_name
FROM (
    SELECT * FROM billed_sales
    UNION ALL
    SELECT * FROM shipped_sales
) AS combined
ORDER BY row_num
LIMIT 100
