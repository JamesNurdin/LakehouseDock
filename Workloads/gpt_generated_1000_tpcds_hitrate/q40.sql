WITH sales_with_email AS (
    SELECT
        ws.ws_order_number AS ws_order_number,
        ws.ws_bill_customer_sk AS ws_bill_customer_sk,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_net_paid AS ws_net_paid,
        d.d_date AS d_date,
        p.p_promo_id AS p_promo_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
      AND d.d_year = 2000
),
sales_discount_inactive AS (
    SELECT
        ws.ws_order_number AS ws_order_number,
        ws.ws_bill_customer_sk AS ws_bill_customer_sk,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_net_paid AS ws_net_paid,
        d.d_date AS d_date,
        p.p_promo_id AS p_promo_id
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'
      AND d.d_year = 2000
),
email_active_orders AS (
    SELECT * FROM sales_with_email
    EXCEPT
    SELECT * FROM sales_discount_inactive
)
SELECT
    c.c_customer_id,
    e.ws_order_number,
    e.d_date,
    e.ws_net_paid,
    LAG(e.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY e.d_date) AS lag_net_paid,
    SUM(e.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY e.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM email_active_orders e
JOIN customer c ON e.ws_bill_customer_sk = c.c_customer_sk
ORDER BY c.c_customer_id, e.d_date
LIMIT 100
