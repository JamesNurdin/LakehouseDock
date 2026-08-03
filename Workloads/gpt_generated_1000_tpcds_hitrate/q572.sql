WITH quarter_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        d.d_date,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        i.i_item_desc,
        i.i_category,
        LAG(ws.ws_net_paid) OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY d.d_date) AS prev_net_paid,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2020
        AND d.d_qoy = 1
        AND regexp_like(c.c_email_address, '^.+@example\\.com$')
        AND i.i_category LIKE 'Electronics%'
        AND i.i_item_sk IN (
            SELECT i2.i_item_sk
            FROM item i2
            WHERE regexp_like(i2.i_item_desc, '(?i)smartphone')
        )
),
avg_quarter_net_paid AS (
    SELECT avg(ws_sub.ws_net_paid) AS avg_net_paid
    FROM web_sales ws_sub
    JOIN date_dim d_sub ON ws_sub.ws_sold_date_sk = d_sub.d_date_sk
    WHERE d_sub.d_year = 2020
      AND d_sub.d_qoy = 1
)
SELECT
    qs.ws_bill_customer_sk AS customer_sk,
    concat(qs.c_first_name, ' ', qs.c_last_name) AS full_name,
    qs.c_email_address,
    sum(qs.ws_net_paid) AS total_net_paid,
    max(qs.prev_net_paid) AS previous_net_paid,
    max(qs.running_total) AS running_total,
    count(*) AS purchase_count,
    substring(qs.c_last_name, 1, 1) AS last_name_initial,
    regexp_extract(qs.i_item_desc, '(?i)(smartphone|tablet)') AS matched_product_type
FROM
    quarter_sales qs
WHERE
    qs.ws_bill_customer_sk NOT IN (
        SELECT sr.sr_customer_sk
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE d_ret.d_year = 2020
    )
GROUP BY
    qs.ws_bill_customer_sk,
    qs.c_first_name,
    qs.c_last_name,
    qs.c_email_address,
    qs.i_item_desc
HAVING
    sum(qs.ws_net_paid) > (SELECT avg_net_paid FROM avg_quarter_net_paid)
ORDER BY
    total_net_paid DESC
LIMIT 100
