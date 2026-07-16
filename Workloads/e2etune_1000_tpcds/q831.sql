WITH category_hour_returns AS (
    SELECT
        i.i_category AS category,
        t.t_hour AS hour_of_day,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_category_id IN (1, 2, 3)
      AND t.t_hour BETWEEN 8 AND 20
      AND i.i_brand_id = 1001001
    GROUP BY i.i_category, t.t_hour
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    category,
    hour_of_day,
    total_return_amount,
    avg_return_quantity,
    return_count,
    RANK() OVER (PARTITION BY hour_of_day ORDER BY total_return_amount DESC) AS rank_by_amount
FROM category_hour_returns
ORDER BY hour_of_day, rank_by_amount
