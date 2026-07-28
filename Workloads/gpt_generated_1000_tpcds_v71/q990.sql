WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_promo_sk,
        (
            SELECT SUM(wr3.wr_return_amt_inc_tax)
            FROM web_returns wr3
            WHERE wr3.wr_order_number = ws.ws_order_number
        ) AS total_return_amt
    FROM web_sales ws
    INNER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    WHERE ws.ws_ship_mode_sk = 10
      AND ws.ws_sold_date_sk = 2450646
)
SELECT
    c.c_birth_country,
    p.p_promo_name,
    COUNT(DISTINCT sr.ws_order_number) AS order_count,
    SUM(sr.ws_net_paid) AS total_net_paid,
    AVG(sr.total_return_amt) AS avg_total_return,
    MIN(sr.ws_net_paid) AS min_net_paid,
    MAX(sr.ws_net_paid) AS max_net_paid
FROM sales_returns sr
JOIN customer c
    ON sr.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN promotion p
    ON sr.ws_promo_sk = p.p_promo_sk
WHERE c.c_birth_country = 'KOREA'
  AND c.c_first_sales_date_sk IN (2450598, 2451825)
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY c.c_birth_country, p.p_promo_name
HAVING SUM(sr.ws_net_paid) > 10000
   AND COUNT(DISTINCT sr.ws_order_number) >= 5
ORDER BY total_net_paid DESC
