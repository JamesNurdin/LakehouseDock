WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_web_page_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        sm.sm_carrier,
        wp.wp_url,
        d.d_year,
        -- extract domain from the page URL
        REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS page_domain,
        -- concatenate first initial and last name
        CONCAT(SUBSTRING(c.c_first_name, 1, 1), '. ', c.c_last_name) AS customer_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND REGEXP_LIKE(c.c_last_name, '^A[[:alpha:]]{2,}$')      -- last names starting with "A" and at least 3 letters
      AND wp.wp_url LIKE '%cat%'
)
SELECT
    sm.sm_carrier AS carrier,
    cd.cd_gender AS gender,
    d.d_year AS sales_year,
    COUNT(DISTINCT filtered_sales.ws_order_number) AS orders_cnt,
    SUM(filtered_sales.ws_net_paid) AS total_net_paid,
    CONCAT(sm.sm_carrier, '_', cd.cd_gender) AS carrier_gender_key,
    MAX(filtered_sales.page_domain) AS sample_domain,
    MIN(filtered_sales.customer_name) AS sample_customer_name
FROM filtered_sales
JOIN ship_mode sm ON filtered_sales.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON filtered_sales.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d ON filtered_sales.ws_sold_date_sk = d.d_date_sk
GROUP BY sm.sm_carrier, cd.cd_gender, d.d_year
HAVING SUM(filtered_sales.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
