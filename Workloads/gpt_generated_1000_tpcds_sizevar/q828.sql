WITH ss_agg AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            ss.ss_addr_sk      AS addr_sk,
            COUNT(*)          AS sales_cnt,
            SUM(ss.ss_net_paid)         AS total_net_paid,
            SUM(ss.ss_quantity)         AS total_quantity
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
          AND ss.ss_net_paid > 50
        GROUP BY ss.ss_customer_sk, ss.ss_addr_sk
    ),
    distinct_reasons AS (
        SELECT DISTINCT r_reason_sk, r_reason_desc
        FROM reason
        WHERE r_reason_desc LIKE '%price%'
    )
SELECT
    c.c_customer_id,
    ca.ca_state,
    cp.cp_department,
    dr.r_reason_desc,
    SUM(cr.cr_return_amount)               AS sum_return_amount,
    SUM(ss_agg.total_net_paid)             AS sum_total_net_paid,
    COUNT(DISTINCT cr.cr_order_number)     AS distinct_orders,
    AVG(ss_agg.total_quantity)            AS avg_quantity_per_customer
FROM catalog_returns cr
FULL OUTER JOIN ss_agg
    ON cr.cr_returning_customer_sk = ss_agg.customer_sk
JOIN customer c
    ON COALESCE(cr.cr_returning_customer_sk, ss_agg.customer_sk) = c.c_customer_sk
JOIN customer_address ca
    ON COALESCE(cr.cr_returning_addr_sk, ss_agg.addr_sk) = ca.ca_address_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN distinct_reasons dr
    ON cr.cr_reason_sk = dr.r_reason_sk
WHERE c.c_birth_year = 1975
  AND c.c_preferred_cust_flag = 'Y'
  AND cp.cp_department = 'Electronics'
  AND cr.cr_return_amount > 100
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_net_paid > 1000
      )
GROUP BY GROUPING SETS (
        (c.c_customer_id, ca.ca_state, cp.cp_department, dr.r_reason_desc),
        (c.c_customer_id, ca.ca_state, cp.cp_department)
    )
ORDER BY sum_return_amount DESC
LIMIT 100
