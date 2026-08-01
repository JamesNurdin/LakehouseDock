WITH sales_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451100 AND 2451500
      AND ss.ss_ext_discount_amt > 50
      AND ss.ss_net_paid_inc_tax < 5000
),
returns_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451100 AND 2451500
      AND cr.cr_refunded_cash > 200
      AND cr.cr_return_quantity > 1
),
common_customers AS (
    SELECT c_customer_sk FROM sales_customers
    INTERSECT
    SELECT c_customer_sk FROM returns_customers
),
agg1 AS (
    SELECT
        cp.cp_catalog_page_id               AS catalog_page,
        r.r_reason_desc                     AS reason,
        wp.wp_type                          AS page_type,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_ext_sales_price)          AS total_sales,
        AVG(ss.ss_ext_discount_amt)         AS avg_discount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
      AND ss.ss_sold_date_sk BETWEEN 2451100 AND 2451500
      AND cp.cp_start_date_sk >= 2451000
    GROUP BY CUBE (cp.cp_catalog_page_id, r.r_reason_desc, wp.wp_type)
),
agg2 AS (
    SELECT
        cp.cp_catalog_page_id               AS catalog_page,
        r.r_reason_desc                     AS reason,
        wp.wp_type                          AS page_type,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_ext_sales_price)          AS total_sales,
        AVG(ss.ss_ext_discount_amt)         AS avg_discount,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 20000 THEN 'VERY HIGH' ELSE 'NORMAL' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
      AND ss.ss_ext_discount_amt > 100
      AND r.r_reason_sk IN (1, 2, 3)
    GROUP BY CUBE (cp.cp_catalog_page_id, r.r_reason_desc, wp.wp_type)
)
SELECT *
FROM (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
) combined
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
