WITH
    returned_customers AS (
        SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk,
               d.d_year
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
          AND ca.ca_location_type = 'apartment'
          AND EXISTS (
              SELECT 1
              FROM warehouse w
              WHERE w.w_warehouse_sk = cr.cr_warehouse_sk
                AND w.w_city = 'Chicago'
          )
    ),
    sales_customers AS (
        SELECT DISTINCT ss.ss_customer_sk AS customer_sk,
               d.d_year
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
          AND ss.ss_quantity > 5
    ),
    catalog_page_customers AS (
        SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk,
               d.d_year
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
        WHERE cp.cp_department = 'Electronics'
          AND d.d_month_seq BETWEEN 1200 AND 1300
    ),
    high_rev_charge AS (
        SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk
        FROM catalog_returns cr
        WHERE cr.cr_reversed_charge > 100
    ),
    union_set AS (
        SELECT customer_sk, d_year FROM returned_customers
        UNION
        SELECT customer_sk, d_year FROM sales_customers
    )
SELECT us.customer_sk,
       us.d_year
FROM union_set us
INTERSECT
SELECT cpc.customer_sk,
       cpc.d_year
FROM catalog_page_customers cpc
EXCEPT
SELECT hrc.customer_sk,
       NULL AS d_year
FROM high_rev_charge hrc
ORDER BY customer_sk
LIMIT 100
