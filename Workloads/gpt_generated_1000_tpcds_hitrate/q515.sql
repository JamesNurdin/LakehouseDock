WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND i.i_product_name LIKE '%Premium%'
    GROUP BY ss.ss_customer_sk
),
returned_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
      AND regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    substring(c.c_email_address, 1, 5) AS email_prefix,
    sa.total_spent,
    sa.sales_cnt,
    SUM(sa.total_spent) OVER (
        ORDER BY sa.total_spent DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_spent,
    LAG(sa.total_spent) OVER (ORDER BY sa.total_spent DESC) AS prev_total_spent
FROM sales_agg sa
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
WHERE sa.ss_customer_sk IN (
    SELECT ss_customer_sk FROM sales_agg
    EXCEPT
    SELECT customer_sk FROM returned_customers
)
  AND EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = sa.ss_customer_sk
      AND ws.ws_quantity > 5
)
ORDER BY sa.total_spent DESC
LIMIT 100
