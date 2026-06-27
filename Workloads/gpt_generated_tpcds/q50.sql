WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_ext_ship_cost,
        ws.ws_net_paid,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_list_price
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
)
SELECT
    ws_site.web_name,
    p.p_promo_name,
    COUNT(DISTINCT fs.ws_bill_customer_sk) AS distinct_customers,
    SUM(fs.ws_quantity) AS total_quantity,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    SUM(fs.ws_ext_discount_amt) AS total_discount,
    SUM(fs.ws_net_profit) AS total_profit,
    AVG(fs.ws_ext_sales_price / NULLIF(fs.ws_quantity, 0)) AS avg_price_per_item
FROM filtered_sales fs
JOIN web_site ws_site
    ON fs.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion p
    ON fs.ws_promo_sk = p.p_promo_sk
GROUP BY ws_site.web_name, p.p_promo_name
ORDER BY total_profit DESC
LIMIT 10
