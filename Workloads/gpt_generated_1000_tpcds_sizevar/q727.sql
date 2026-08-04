WITH sp AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number,
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        p.p_start_date_sk
    FROM store_sales ss
    RIGHT OUTER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    sp.p_promo_id,
    sp.p_promo_name,
    d.d_year,
    CASE WHEN sp.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(COALESCE(sp.ss_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(sp.ss_ext_tax, 0)) AS total_tax,
    AVG(COALESCE(sp.ss_ext_discount_amt, 0)) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    COUNT(DISTINCT c.c_customer_sk) AS customer_cnt
FROM sp
FULL OUTER JOIN date_dim d
    ON sp.p_start_date_sk = d.d_date_sk
LEFT JOIN time_dim t
    ON sp.ss_sold_time_sk = t.t_time_sk
LEFT JOIN customer c
    ON sp.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON sp.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON sp.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws
    ON d.d_date_sk = ws.ws_sold_date_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND ca.ca_state = 'CA'
    AND cd.cd_credit_rating = 'High Risk'
    AND sp.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM web_sales w2
        WHERE w2.ws_order_number = ws.ws_order_number
          AND w2.ws_net_profit > 500
    )
GROUP BY
    sp.p_promo_id,
    sp.p_promo_name,
    d.d_year,
    CASE WHEN sp.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END
ORDER BY total_net_paid DESC
LIMIT 100
