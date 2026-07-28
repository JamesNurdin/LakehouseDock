WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_returned_time_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 1
)
SELECT
    t.t_time_id,
    t.t_meal_time,
    r.r_reason_desc,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(fr.cr_return_amount) DESC) AS rn_by_reason,
    RANK() OVER (ORDER BY SUM(fr.cr_return_amount) DESC) AS overall_return_rank
FROM filtered_returns fr
JOIN catalog_sales cs
    ON fr.cr_order_number = cs.cs_order_number
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON fr.cr_returned_time_sk = t.t_time_sk
WHERE r.r_reason_id IN ('AAAAAAAAHAAAAAAA', 'AAAAAAAAJAAAAAAA')
  AND t.t_meal_time = 'dinner'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = fr.cr_order_number
          AND cs2.cs_net_profit > 1000
    )
GROUP BY
    t.t_time_id,
    t.t_meal_time,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
