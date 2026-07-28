WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_salutation,
        c_first_name,
        c_last_name,
        c_email_address,
        regexp_extract(c_email_address, '@([^.]*)\\.', 1) AS email_domain
    FROM tpcds.customer
    WHERE regexp_like(c_email_address, '^.+@example\\.com$')
      AND c_salutation LIKE 'Mr.%'
),
returns_joined AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
inventory_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM tpcds.inventory
    GROUP BY inv_date_sk
)
SELECT
    fc.c_salutation,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    fc.email_domain,
    d.d_year,
    SUM(rj.wr_return_amt) AS total_return_amount,
    SUM(rj.wr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT rj.wr_returned_date_sk) AS distinct_return_days,
    SUM(i.total_inventory_qty) AS total_inventory_on_return_dates
FROM filtered_customers fc
JOIN returns_joined rj ON fc.c_customer_sk = rj.wr_refunded_customer_sk
JOIN tpcds.date_dim d ON rj.wr_returned_date_sk = d.d_date_sk
LEFT JOIN inventory_agg i ON i.inv_date_sk = rj.wr_returned_date_sk
GROUP BY
    fc.c_salutation,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name),
    fc.email_domain,
    d.d_year
ORDER BY total_return_amount DESC
LIMIT 100
