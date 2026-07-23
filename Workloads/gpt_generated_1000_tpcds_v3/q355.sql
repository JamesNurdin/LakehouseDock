/* Goal: Analyze return amounts by catalog department, warehouse state, and time of day for Irish customers, focusing on high-value returns. */
WITH returns_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_catalog_page_sk,
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451000
      AND cr_return_quantity > 0
      AND cr_return_amount > 0
      AND cr_returned_time_sk IS NOT NULL
    GROUP BY
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_catalog_page_sk,
        cr_returning_customer_sk
)
SELECT
    cp.cp_department,
    w.w_state,
    CASE
        WHEN td.t_hour BETWEEN 0 AND 11 THEN 'Morning'
        WHEN td.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    COUNT(DISTINCT ra.return_cnt) AS distinct_return_events,
    SUM(ra.total_return_amount) AS sum_return_amount,
    AVG(ra.avg_return_amount) AS avg_return_amount_per_group,
    CASE
        WHEN SUM(ra.total_return_amount) > 10000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    (SELECT MAX(cr_return_amount) FROM catalog_returns) AS overall_max_return_amount
FROM returns_agg ra
JOIN time_dim td
    ON ra.cr_returned_time_sk = td.t_time_sk
JOIN catalog_page cp
    ON ra.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON ra.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer returning_cust
    ON ra.cr_returning_customer_sk = returning_cust.c_customer_sk
JOIN customer_address cur_addr
    ON returning_cust.c_current_addr_sk = cur_addr.ca_address_sk
JOIN web_page wp
    ON wp.wp_customer_sk = returning_cust.c_customer_sk
WHERE cp.cp_department = 'Electronics'
  AND w.w_state = 'CA'
  AND returning_cust.c_birth_country = 'IRELAND'
  AND cur_addr.ca_country = 'IRELAND'
  AND td.t_meal_time = 'Lunch'
GROUP BY
    cp.cp_department,
    w.w_state,
    CASE
        WHEN td.t_hour BETWEEN 0 AND 11 THEN 'Morning'
        WHEN td.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY sum_return_amount DESC
LIMIT 100
