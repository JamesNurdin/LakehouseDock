WITH ws_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
        ) AS max_promo_cost
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
          AND d.d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_site_sk
)
SELECT
    sm.sm_type,
    AVG(wa.total_net_paid) AS avg_total_net_paid,
    SUM(wa.order_cnt) AS sum_orders,
    AVG(wa.max_promo_cost) AS avg_max_promo_cost
FROM ws_agg wa
JOIN date_dim d            ON wa.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t            ON wa.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm          ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p           ON wa.ws_promo_sk = p.p_promo_sk
JOIN customer c            ON wa.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site ws           ON wa.ws_web_site_sk = ws.web_site_sk
WHERE sm.sm_type = 'AIR'
  AND p.p_purpose = 'Discount'
  AND c.c_preferred_cust_flag = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY sm.sm_type
HAVING AVG(wa.total_net_paid) > 1000
ORDER BY avg_total_net_paid DESC
LIMIT 100
