WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        cr.cr_return_amount > 100
        AND ca.ca_state = 'CA'
        AND d.d_year = 2001
        AND ws.ws_quantity >= 2
        AND ws_site.web_state = 'TX'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_type = 'home'
        )
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        d.d_year
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.ca_state,
    b.d_year,
    b.total_return_amount,
    b.total_sales_amount,
    b.total_net_profit,
    ROUND(b.total_return_amount / NULLIF(b.return_orders, 0), 2) AS avg_return_per_order,
    RANK() OVER (ORDER BY b.total_sales_amount DESC) AS sales_rank,
    (SELECT max(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2001) AS max_date_2001
FROM base b
ORDER BY b.total_sales_amount DESC
LIMIT 100
