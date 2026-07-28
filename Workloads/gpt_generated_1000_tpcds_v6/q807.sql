WITH customer_site_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ws.ws_list_price > 50
      AND w.web_county IN ('Walker County', 'Huron County')
      AND w.web_street_type = 'Court'
      AND sm.sm_type = 'AIR'
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_ext_discount_amt > 10000
      )
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk
)
SELECT
    css.c_customer_sk,
    css.c_first_name,
    css.c_last_name,
    w.web_name,
    sm.sm_type,
    css.total_net_paid,
    css.total_discount,
    css.order_cnt,
    RANK() OVER (PARTITION BY w.web_name ORDER BY css.total_net_paid DESC) AS revenue_rank,
    SUM(css.total_net_paid) OVER (
        PARTITION BY w.web_name
        ORDER BY css.total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_site_sales
FROM customer_site_sales css
JOIN web_site w
    ON css.ws_web_site_sk = w.web_site_sk
JOIN ship_mode sm
    ON css.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY w.web_name, revenue_rank
LIMIT 100
