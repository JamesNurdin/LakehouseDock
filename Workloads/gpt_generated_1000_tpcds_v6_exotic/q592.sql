/* goal: Compare high‑value returns made in the morning with high‑value web sales made in the evening for customers born in August who are marked as preferred, and show the top records by monetary amount. */
WITH returns AS (
    SELECT
        c.c_customer_id            AS customer_id,
        c.c_birth_month            AS birth_month,
        t.t_sub_shift              AS shift,
        cr.cr_return_amount        AS amount,
        cr.cr_refunded_cash        AS metric,
        (
            SELECT SUM(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
        )                         AS extra_metric,
        'return'                  AS source
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND c.c_birth_month = 8
      AND c.c_preferred_cust_flag = 'Y'
),
sales AS (
    SELECT
        c.c_customer_id            AS customer_id,
        c.c_birth_month            AS birth_month,
        t.t_sub_shift              AS shift,
        ws.ws_ext_sales_price      AS amount,
        ws.ws_net_paid             AS metric,
        (
            SELECT COUNT(*)
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
        )                         AS extra_metric,
        'sale'                    AS source
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'evening'
      AND c.c_birth_month = 8
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    customer_id,
    birth_month,
    shift,
    amount,
    metric,
    extra_metric,
    source
FROM returns
UNION ALL
SELECT
    customer_id,
    birth_month,
    shift,
    amount,
    metric,
    extra_metric,
    source
FROM sales
ORDER BY amount DESC
LIMIT 100
