WITH item_profit AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    c.c_customer_id,
    i.i_product_name,
    CONCAT(i.i_color, '_', i.i_size) AS color_size,
    ws.ws_net_paid,
    ip.total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY ws.ws_net_paid DESC) AS country_rank,
    CASE
        WHEN regexp_like(i.i_product_name, '^A.*') THEN 'StartsWithA'
        ELSE 'Other'
    END AS product_name_category
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN item_profit ip ON ws.ws_item_sk = ip.ws_item_sk
WHERE
    c.c_birth_country LIKE '%A%'
    AND NOT regexp_like(i.i_product_name, '.*[0-9]{2}.*')
    AND ip.total_net_paid > (SELECT AVG(total_net_paid) FROM item_profit)
ORDER BY ws.ws_net_paid DESC
LIMIT 100
