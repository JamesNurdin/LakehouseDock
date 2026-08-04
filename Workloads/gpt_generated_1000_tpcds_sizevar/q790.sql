/*
  Goal: Identify the most valuable return combinations by state, return reason, department and year, using a sampled fact table, full outer join to warehouse, multiple filters, a cube aggregation, window ranking, a correlated scalar subquery and distinct counts.
*/
WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)    -- sample 10% of the fact rows
),
joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        ca_refund.ca_location_type,
        ca_refund.ca_address_sk
    FROM sampled_returns cr
    FULL OUTER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND w.w_state = 'CA'                    -- predicate kept in the join to preserve unmatched rows
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    INNER JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    WHERE d.d_year = 2001                           -- filter 1
      AND r.r_reason_desc = 'Customer not satisfied' -- filter 2
      AND cp.cp_department = 'Electronics'           -- filter 3
      AND cp.cp_type = 'Standard'                    -- filter 4
      AND cr.cr_return_amount > 1000                -- filter 5
      AND ca_refund.ca_location_type = 'apartment'  -- filter 6
)
SELECT
    j.w_state,
    j.r_reason_desc,
    j.cp_department,
    j.d_year,
    COUNT(DISTINCT j.cr_order_number) AS distinct_orders,
    SUM(j.cr_return_amt_inc_tax)       AS total_return_inc_tax,
    AVG(j.cr_return_tax)               AS avg_return_tax,
    ROW_NUMBER() OVER (ORDER BY SUM(j.cr_return_amt_inc_tax) DESC) AS rn_total_return,
    (SELECT COUNT(*) FROM warehouse w2 WHERE w2.w_state = j.w_state) AS warehouses_in_state_cnt
FROM joined j
GROUP BY CUBE (j.w_state, j.r_reason_desc, j.cp_department, j.d_year)
HAVING COUNT(*) > 5
ORDER BY total_return_inc_tax DESC
LIMIT 100
