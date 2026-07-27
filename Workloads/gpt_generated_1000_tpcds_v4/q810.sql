WITH combined AS (
    SELECT
        ca.ca_state AS ca_state,
        wsite.web_site_sk AS web_site_sk,
        wsite.web_name AS web_name,
        ss.ss_ext_sales_price AS store_sales_amount,
        ws.ws_ext_sales_price AS web_sales_amount,
        ss.ss_customer_sk AS customer_sk,
        ca.ca_address_sk AS address_sk
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cd.cd_purchase_estimate > 5000
        AND ca.ca_state = 'CA'
        AND ws.ws_ext_tax > 20
        AND wsite.web_rec_start_date >= DATE '2001-01-01'
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_ship_addr_sk = ca.ca_address_sk
                AND ws2.ws_ext_ship_cost > 1000
        )
),
aggregated AS (
    SELECT
        ca_state AS state,
        web_name,
        (store_sales_amount + web_sales_amount) AS total_sales,
        customer_sk
    FROM combined
)
SELECT
    state,
    web_name,
    SUM(total_sales) AS total_sales,
    COUNT(DISTINCT customer_sk) AS distinct_customers
FROM aggregated
GROUP BY state, web_name
HAVING SUM(total_sales) > 100000
ORDER BY total_sales DESC
LIMIT 100
