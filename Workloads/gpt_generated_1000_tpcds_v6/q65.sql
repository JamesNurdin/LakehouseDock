WITH promo_sales_2001 AS (
    SELECT
        d.d_year AS sales_year,
        p.p_channel_email AS promo_email_channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND p.p_channel_email = 'Y'
    GROUP BY d.d_year, p.p_channel_email
),
promo_sales_2000 AS (
    SELECT
        d.d_year AS sales_year,
        p.p_channel_email AS promo_email_channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND p.p_channel_email = 'N'
    GROUP BY d.d_year, p.p_channel_email
)
SELECT *
FROM promo_sales_2001
UNION ALL
SELECT *
FROM promo_sales_2000
ORDER BY sales_year DESC, promo_email_channel
LIMIT 100
