WITH address_array AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ARRAY[ca_city, ca_state] AS loc_parts
    FROM customer_address
),
address_unnested AS (
    SELECT
        aa.ca_address_sk,
        aa.ca_city,
        aa.ca_state,
        loc_part,
        ROW_NUMBER() OVER (PARTITION BY aa.ca_address_sk ORDER BY loc_part) AS rn_loc
    FROM address_array aa
    CROSS JOIN UNNEST(aa.loc_parts) AS t(loc_part)
),
customer_returns AS (
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_customer_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
all_customers_excluding_returns AS (
    SELECT c.c_customer_sk
    FROM customer c
    EXCEPT
    SELECT cr.cr_refunded_customer_sk
    FROM catalog_returns cr
),
full_join_sales_returns AS (
    SELECT
        ss.ss_customer_sk AS sale_cust_sk,
        ss.ss_sold_date_sk AS sale_date_sk,
        ss.ss_sold_time_sk AS sale_time_sk,
        ss.ss_net_paid,
        cr.cr_refunded_customer_sk AS return_cust_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_returned_time_sk AS return_time_sk,
        cr.cr_return_amount
    FROM store_sales ss
    FULL OUTER JOIN catalog_returns cr
        ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
        AND ss.ss_sold_time_sk = cr.cr_returned_time_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(d.d_date, DATE '1900-01-01') DESC) AS row_num,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS full_location,
    SUBSTRING(ca.ca_city, 1, 3) AS city_prefix,
    CASE
        WHEN REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
        THEN 'valid_email'
        ELSE 'invalid_email'
    END AS email_validity,
    REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain,
    ssr.ss_net_paid,
    ssr.cr_return_amount,
    CASE
        WHEN ssr.ss_net_paid > 0 THEN ssr.cr_return_amount / ssr.ss_net_paid
        ELSE NULL
    END AS return_to_sales_ratio,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk) AS total_store_txns,
    ssa.total_sales,
    ssa.total_profit,
    cragg.total_return_amount,
    cragg.total_net_loss,
    ua.loc_part AS address_component,
    ua.rn_loc AS address_component_seq
FROM
    full_join_sales_returns ssr
    LEFT JOIN customer c ON c.c_customer_sk = COALESCE(ssr.sale_cust_sk, ssr.return_cust_sk)
    LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN address_unnested ua ON ua.ca_address_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON d.d_date_sk = COALESCE(ssr.sale_date_sk, ssr.return_date_sk)
    LEFT JOIN store_sales_agg ssa ON ssa.cust_sk = c.c_customer_sk
    LEFT JOIN customer_returns cragg ON cragg.cust_sk = c.c_customer_sk
WHERE
    (REGEXP_LIKE(ca.ca_city, '^A') OR ca.ca_city LIKE '%ville%')
    AND c.c_customer_sk IN (SELECT c_customer_sk FROM all_customers_excluding_returns)
ORDER BY
    row_num
LIMIT 100
