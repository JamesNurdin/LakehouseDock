WITH filtered_returns AS (
    SELECT
        cr_returned_time_sk,
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_ship_cost,
        cr_reversed_charge,
        cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity > 1
      AND cr_return_amount BETWEEN 10 AND 500
      AND cr_return_ship_cost NOT IN (58.31, 308.00)
      AND cr_reversed_charge >= 20
      AND cr_order_number IN (5267295, 5267281, 5267298)
)
SELECT
    td.t_meal_time,
    td.t_hour,
    COUNT(*) AS cnt_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MIN(fr.cr_return_ship_cost) AS min_ship_cost,
    MAX(fr.cr_reversed_charge) AS max_reversed_charge
FROM filtered_returns fr
JOIN time_dim td
  ON fr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_second BETWEEN 0 AND 15
  AND td.t_meal_time IN ('breakfast', 'lunch')
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_time_sk = fr.cr_returned_time_sk
          AND cr2.cr_return_amount > 1000
    )
GROUP BY td.t_meal_time, td.t_hour
ORDER BY total_return_amount DESC
LIMIT 100
