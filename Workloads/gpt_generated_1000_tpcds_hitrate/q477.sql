WITH sales_detail AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        SUM(ws.ws_net_paid) OVER (
            PARTITION BY ws.ws_bill_customer_sk
            ORDER BY ws.ws_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_paid,
        ROW_NUMBER() OVER (
            PARTITION BY ws.ws_bill_customer_sk
            ORDER BY ws.ws_sold_date_sk DESC
        ) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
),

sales_latest AS (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        running_total_paid
    FROM sales_detail
    WHERE rn = 1
),

returns_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_customer_sk
)

SELECT
    sl.customer_sk,
    sl.c_first_name,
    sl.c_last_name,
    sl.running_total_paid
FROM sales_latest sl
WHERE sl.running_total_paid > (
        SELECT AVG(running_total_paid) FROM sales_latest
      )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = sl.customer_sk
          AND ws2.ws_quantity > 5
      )
EXCEPT
SELECT
    ra.customer_sk,
    c.c_first_name,
    c.c_last_name,
    ra.total_return_amount
FROM returns_agg ra
JOIN customer c ON ra.customer_sk = c.c_customer_sk
ORDER BY running_total_paid DESC
LIMIT 100
