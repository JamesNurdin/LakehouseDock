WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_warehouse_sk,
        cr.cr_catalog_page_sk,
        cp.cp_department,
        cp.cp_description,
        w.w_warehouse_name,
        w.w_city,
        w.w_street_type,
        w.w_street_name,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        regexp_extract(cp.cp_description, '(?i)(damage|defect)', 1) AS issue_type,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        substring(w.w_street_name, 1, 10) AS street_name_prefix
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '(?i)damage|defect')
      AND w.w_street_type LIKE 'A%'
      AND regexp_extract(c.c_email_address, '@(.+)$', 1) LIKE '%.com'
),
agg AS (
    SELECT
        w_warehouse_name,
        w_city,
        cp_department,
        count(distinct cr_order_number) AS num_returns,
        sum(cr_return_amount) AS total_return_amount,
        max(issue_type) AS issue_type,
        max(customer_full_name) AS sample_customer,
        max(street_name_prefix) AS sample_street_prefix
    FROM filtered_returns
    GROUP BY w_warehouse_name, w_city, cp_department
)
SELECT
    w_warehouse_name,
    w_city,
    cp_department,
    num_returns,
    total_return_amount,
    issue_type,
    sample_customer,
    row_number() OVER (PARTITION BY w_warehouse_name ORDER BY total_return_amount DESC) AS dept_return_rank,
    sum(total_return_amount) OVER (PARTITION BY w_warehouse_name ORDER BY total_return_amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
