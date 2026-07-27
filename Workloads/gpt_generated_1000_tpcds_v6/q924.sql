WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number,
        cr.cr_return_quantity,
        c.c_birth_country,
        d.d_year,
        i.inv_item_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN inventory i
        ON d.d_date_sk = i.inv_date_sk
    WHERE cr.cr_warehouse_sk = 14
      AND c.c_birth_country = 'JORDAN'
      AND d.d_year = 2001
      AND i.inv_item_sk = 101449
),
agg AS (
    SELECT
        d_year,
        c_birth_country,
        cr_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        SUM(cr_return_quantity) AS total_quantity,
        MAX(cr_return_amount) AS max_return_amount
    FROM base
    GROUP BY d_year, c_birth_country, cr_warehouse_sk
)
SELECT
    d_year,
    c_birth_country,
    cr_warehouse_sk,
    total_return_amount,
    avg_return_tax,
    distinct_orders,
    total_quantity,
    max_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c_birth_country ORDER BY total_return_amount DESC) AS rn_by_country
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
