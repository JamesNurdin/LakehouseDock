WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        w.w_warehouse_sq_ft,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amt_inc_tax > 500
      AND cr.cr_return_quantity >= 1
      AND w.w_state IN ('CA', 'NY', 'TX')
      AND w.w_warehouse_sq_ft > 200000
      AND w.w_street_type IN ('Road', 'Way')
    GROUP BY w.w_warehouse_id, w.w_state, w.w_city, w.w_warehouse_sq_ft
)
SELECT
    w_state,
    AVG(total_return_inc_tax) AS avg_return_inc_tax,
    SUM(total_quantity) AS sum_quantity
FROM warehouse_returns
WHERE total_quantity > 5
GROUP BY w_state
HAVING AVG(total_return_inc_tax) > 1000

UNION DISTINCT

SELECT
    w_state,
    AVG(total_return_inc_tax) AS avg_return_inc_tax,
    SUM(total_quantity) AS sum_quantity
FROM warehouse_returns
WHERE total_quantity <= 5
GROUP BY w_state
HAVING AVG(total_return_inc_tax) <= 1000

ORDER BY w_state, avg_return_inc_tax DESC
