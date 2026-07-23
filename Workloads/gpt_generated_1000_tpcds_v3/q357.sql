WITH base AS (
    SELECT
        cp.cp_department,
        ca_ret.ca_city,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_store_credit,
        i.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END AS high_return_flag,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'Zero' END AS return_amount_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'
      AND ca_ref.ca_state = 'CA'
      AND w.w_city = 'Oakland'
      AND i.inv_quantity_on_hand > 0
      AND cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
          JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
          WHERE p.p_item_sk = cr.cr_item_sk
            AND d.d_date BETWEEN d_start.d_date AND d_end.d_date
      )
),

dept_city_agg AS (
    SELECT
        cp_department,
        ca_city,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN high_return_flag = 1 THEN cr_return_amount ELSE 0 END) AS high_return_amount,
        SUM(CASE WHEN return_amount_category = 'Positive' THEN cr_return_amount ELSE 0 END) AS positive_return_amount
    FROM base
    GROUP BY cp_department, ca_city
)

SELECT
    cp_department,
    AVG(total_return_amount) AS avg_total_return_amount_across_cities,
    SUM(return_cnt) AS total_returns,
    MAX(high_return_amount) AS max_high_return_amount
FROM dept_city_agg
GROUP BY cp_department
HAVING SUM(return_cnt) > 10
ORDER BY avg_total_return_amount_across_cities DESC
LIMIT 100
