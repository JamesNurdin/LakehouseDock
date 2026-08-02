WITH store_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE t.t_shift = 'first'
      AND s.s_state = 'CA'
),
web_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE t.t_shift = 'first'
      AND w.web_state = 'CA'
)
SELECT sc.c_customer_id, sc.c_first_name, sc.c_last_name
FROM store_customers sc
EXCEPT
SELECT wc.c_customer_id, wc.c_first_name, wc.c_last_name
FROM web_customers wc
LIMIT 100
