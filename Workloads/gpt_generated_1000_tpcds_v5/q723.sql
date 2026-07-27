WITH filtered_returns AS (
    SELECT
        cr.*, 
        dr_return.d_year,
        w.w_warehouse_name,
        cp.cp_department,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk) AS avg_return_amount_warehouse
    FROM catalog_returns cr
    JOIN date_dim dr_return
        ON cr.cr_returned_date_sk = dr_return.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dr_start
        ON cp.cp_start_date_sk = dr_start.d_date_sk
    JOIN date_dim dr_end
        ON cp.cp_end_date_sk = dr_end.d_date_sk
    JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer c_return
        ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE c_return.c_birth_country = 'CAYMAN ISLANDS'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca2
          WHERE ca2.ca_address_sk = cr.cr_returning_addr_sk
            AND ca2.ca_city = w.w_city
      )
)
SELECT
    w_warehouse_name,
    cp_department,
    d_year,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MAX(avg_return_amount_warehouse) AS avg_return_amount_warehouse
FROM filtered_returns
GROUP BY ROLLUP (w_warehouse_name, cp_department, d_year)
HAVING SUM(cr_return_amount) > 10000
ORDER BY w_warehouse_name, cp_department, d_year NULLS LAST
LIMIT 100
