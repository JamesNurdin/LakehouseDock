WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_site_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        cp.cp_description,
        d.d_year,
        d.d_moy,
        w.web_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE
        regexp_like(c.c_email_address, '@gmail\\.com$')
        AND regexp_like(cp.cp_description, '(?i)sale')
        AND w.web_name LIKE '%Shop%'
)
SELECT
    ws.web_name,
    ws.d_year,
    ws.d_moy AS month,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    ARRAY_JOIN(
        ARRAY_DISTINCT(
            ARRAY_AGG(regexp_extract(ws.c_email_address, '@([^.]*)\\.', 1))
        ),
        ','
    ) AS distinct_email_domains,
    CONCAT(MIN(ws.c_first_name), ' ', MIN(ws.c_last_name)) AS sample_customer_name
FROM filtered_sales ws
GROUP BY ws.web_name, ws.d_year, ws.d_moy
ORDER BY total_net_profit DESC
LIMIT 100
