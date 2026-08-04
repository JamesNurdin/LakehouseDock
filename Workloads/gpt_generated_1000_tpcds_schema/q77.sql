WITH item_returns AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_reason_sk,
        SUM(sr_return_amt_inc_tax) AS item_return_sum
    FROM store_returns
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_return_time_sk, sr_reason_sk
),
filtered_items AS (
    SELECT *
    FROM item_returns
    WHERE item_return_sum > 50
)
SELECT
    r.r_reason_desc,
    i.i_category,
    SUM(fr.item_return_sum) AS total_return,
    COUNT(DISTINCT d.d_date) AS distinct_return_dates,
    (SELECT AVG(item_return_sum) FROM item_returns) AS avg_return_overall
FROM filtered_items fr
JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON fr.sr_return_time_sk = t.t_time_sk
JOIN item i ON fr.sr_item_sk = i.i_item_sk
JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2002
  AND d.d_current_quarter = 'Y'
  AND i.i_class = 'furniture'
  AND i.i_color = 'red'
  AND t.t_am_pm = 'PM'
  AND t.t_meal_time = 'dinner'
  AND i.i_item_id IN (
        SELECT i2.i_item_id
        FROM item i2
        JOIN store_returns sr2 ON i2.i_item_sk = sr2.sr_item_sk
        WHERE sr2.sr_return_amt_inc_tax > 2000
        EXCEPT
        SELECT i3.i_item_id
        FROM item i3
        JOIN store_returns sr3 ON i3.i_item_sk = sr3.sr_item_sk
        JOIN reason r3 ON sr3.sr_reason_sk = r3.r_reason_sk
        WHERE r3.r_reason_desc = 'Did not like the color'
    )
GROUP BY r.r_reason_desc, i.i_category
HAVING SUM(fr.item_return_sum) > 1000
ORDER BY total_return DESC
LIMIT 100
