WITH promo_filtered AS (
    SELECT DISTINCT p.p_promo_sk,
                    p.p_promo_name
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
),
sales_with_details AS (
    SELECT ws.ws_bill_customer_sk,
           ws.ws_promo_sk,
           ws.ws_order_number,
           ws.ws_net_paid,
           ws.ws_ext_discount_amt,
           ws.ws_sold_time_sk,
           ws.ws_bill_addr_sk,
           ws.ws_web_page_sk,
           td.t_hour,
           ca.ca_city,
           p.p_promo_name,
           wp.wp_url
    FROM web_sales ws
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promo_filtered p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 18
      AND (wp.wp_url LIKE '%/sale/%' OR regexp_like(wp.wp_url, '^https?://.*sale.*'))
)
SELECT
    swd.ws_bill_customer_sk AS customer_sk,
    swd.ca_city AS customer_city,
    swd.p_promo_name AS promotion,
    CONCAT('Promo: ', swd.p_promo_name) AS promo_label,
    SUBSTRING(MIN(swd.wp_url), 1, 30) AS url_prefix,
    COUNT(DISTINCT swd.ws_order_number) AS distinct_orders,
    SUM(swd.ws_net_paid) AS total_net_paid,
    AVG(swd.ws_ext_discount_amt) AS avg_discount_amount,
    CASE
        WHEN SUM(swd.ws_net_paid) > 1000 THEN 'high'
        ELSE 'low'
    END AS net_paid_category,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = swd.ws_promo_sk
    ) AS promo_avg_net_paid
FROM sales_with_details swd
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = swd.ws_order_number
)
GROUP BY
    swd.ws_bill_customer_sk,
    swd.ca_city,
    swd.p_promo_name,
    swd.ws_promo_sk
ORDER BY total_net_paid DESC
LIMIT 100
