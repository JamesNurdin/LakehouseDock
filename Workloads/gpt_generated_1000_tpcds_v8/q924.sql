WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10) -- 10% random sample
),
filtered_returns AS (
    SELECT *
    FROM sampled_returns sr
    WHERE sr.cr_return_amount > 500
      AND sr.cr_return_tax < 100
      AND sr.cr_return_ship_cost BETWEEN 5 AND 500
      AND sr.cr_return_quantity >= 1
      AND EXISTS (
            SELECT 1
            FROM reason r_sub
            WHERE r_sub.r_reason_sk = sr.cr_reason_sk
              AND r_sub.r_reason_desc LIKE '%defect%'
      )
),
reason_excluded AS (
    SELECT r_reason_sk
    FROM reason
    EXCEPT
    SELECT cr2.cr_reason_sk
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount = 0
)
SELECT
    w.w_warehouse_name,
    cp.cp_department,
    t.t_hour,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
FULL OUTER JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
LEFT JOIN time_dim t
    ON fr.cr_returned_time_sk = t.t_time_sk
LEFT JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
LEFT JOIN customer c
    ON fr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON fr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE fr.cr_reason_sk IN (SELECT r_reason_sk FROM reason_excluded)
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_current_price > 100
  AND w.w_state = 'CA'
GROUP BY w.w_warehouse_name, cp.cp_department, t.t_hour
HAVING SUM(fr.cr_return_amount) > 2000
ORDER BY total_return_amount DESC
LIMIT 100
