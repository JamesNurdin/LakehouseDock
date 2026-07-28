WITH max_ship AS (
    SELECT max(ws_ext_ship_cost) AS max_ship_cost
    FROM web_sales
)
SELECT
    website,
    total_net_paid_inc_tax,
    order_cnt,
    total_quantity,
    max_ship_cost
FROM (
    SELECT
        ws_site.web_name AS website,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        (SELECT max_ship_cost FROM max_ship) AS max_ship_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE c.c_salutation = 'Mr.'
      AND wp.wp_link_count > 10
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_ext_ship_cost > 2000
      )
    GROUP BY ws_site.web_name
    UNION ALL
    SELECT
        ws_site.web_name AS website,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        (SELECT max_ship_cost FROM max_ship) AS max_ship_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE c.c_salutation = 'Ms.'
      AND wp.wp_max_ad_count = 0
      AND ws.ws_order_number IN (
          SELECT ws2.ws_order_number
          FROM web_sales ws2
          WHERE ws2.ws_ext_ship_cost > 2500
      )
    GROUP BY ws_site.web_name
) AS combined
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
