WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        w.w_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'UPS'
      AND c.c_salutation = 'Mr.'
      AND wp.wp_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        w.w_state
)
SELECT
    cs.c_salutation,
    cs.c_first_name,
    cs.c_last_name,
    cs.w_state,
    cs.total_sales,
    cs.order_count,
    ROW_NUMBER() OVER (PARTITION BY cs.w_state ORDER BY cs.total_sales DESC) AS state_sales_rank,
    CASE
        WHEN cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM customer_sales cs
ORDER BY cs.total_sales DESC
LIMIT 100
