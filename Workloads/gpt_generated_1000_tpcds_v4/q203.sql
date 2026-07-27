WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_addr_sk,
        wsite.web_suite_number,
        wsite.web_name,
        ca.ca_city
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(wsite.web_suite_number, '^Suite \d+$')
      AND wsite.web_name LIKE '%Shop%'
      AND ca.ca_city LIKE 'A%'
)
SELECT
    wh.w_warehouse_name,
    regexp_extract(fs.web_suite_number, '\\d+') AS suite_number,
    MAX(substring(fs.web_name FROM 1 FOR 5)) AS name_prefix,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_net_paid) AS avg_paid,
    COUNT(DISTINCT fs.ws_order_number) AS orders_cnt
FROM filtered_sales fs
JOIN tpcds.warehouse wh
    ON fs.ws_warehouse_sk = wh.w_warehouse_sk
GROUP BY
    wh.w_warehouse_name,
    regexp_extract(fs.web_suite_number, '\\d+')
ORDER BY total_profit DESC
LIMIT 100
