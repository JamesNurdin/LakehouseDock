/*
Goal: Analyze store return performance by customer, product category, and return reason, focusing on high‑value returns and filtering for a specific product formulation, birth month, shift, and sufficient inventory. The query also ensures that the item has at least one web return (semi‑join via EXISTS).
*/
WITH filtered AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        r.r_reason_desc,
        td.t_shift,
        CASE WHEN sr.sr_return_amt > 200 THEN 'High' ELSE 'Low' END AS return_level,
        sr.sr_return_amt
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_formulation = '85seashell1303417084'
      AND c.c_birth_month = 7
      AND td.t_shift = 'first'
      AND inv.inv_quantity_on_hand > 50
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
              AND wr.wr_return_quantity > 0
        )
)
SELECT
    c_customer_id,
    i_category,
    r_reason_desc,
    t_shift,
    return_level,
    COUNT(*) AS return_count,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_amt) AS avg_return_amount,
    MIN(sr_return_amt) AS min_return_amount,
    MAX(sr_return_amt) AS max_return_amount
FROM filtered
GROUP BY
    c_customer_id,
    i_category,
    r_reason_desc,
    t_shift,
    return_level
ORDER BY total_return_amount DESC
LIMIT 100
