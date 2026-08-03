WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
)
SELECT
    DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    sr.total_return_qty,
    sr.total_return_amt,
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_ext_wholesale_cost,
    ws.ws_net_paid_inc_tax,
    LAG(ws.ws_net_paid_inc_tax) OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk) AS prev_net_paid,
    SUM(ws.ws_net_paid_inc_tax) OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk ROWS UNBOUNDED PRECEDING) AS running_total_paid,
    (SELECT SUM(ws2.ws_ext_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) AS total_sales_for_customer,
    RANK() OVER (
        ORDER BY (SELECT SUM(ws2.ws_ext_sales_price)
                  FROM web_sales ws2
                  WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) DESC
    ) AS sales_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN sr_agg sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    c.c_birth_year BETWEEN 1950 AND 1965
    AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
    AND wp.wp_image_count >= 2
    AND wp.wp_rec_start_date >= DATE '1999-01-01'
    AND ws.ws_ext_wholesale_cost > 1500.00
    AND ws.ws_net_paid_inc_tax > 200.00
    AND c.c_customer_sk NOT IN (
        SELECT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 10
    )
    AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
          AND wp2.wp_image_count > 3
    )
ORDER BY sales_rank, c.c_customer_id
LIMIT 100
