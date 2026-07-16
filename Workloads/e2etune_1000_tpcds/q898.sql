WITH agg AS (
    SELECT
        i.i_category,
        i.i_category_id,
        s.sm_carrier,
        COUNT(DISTINCT i.i_item_id) AS distinct_item_cnt,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost,
        AVG(i.i_current_price) AS avg_current_price,
        MIN(i.i_current_price) AS min_current_price,
        MAX(i.i_current_price) AS max_current_price,
        AVG(i.i_current_price - i.i_wholesale_cost) AS avg_price_margin
    FROM item i
    JOIN ship_mode s
        ON i.i_category_id = s.sm_ship_mode_sk
    WHERE
        i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_wholesale_cost > 1.00
        AND i.i_color IN ('red', 'pink', 'rosy')
    GROUP BY
        i.i_category,
        i.i_category_id,
        s.sm_carrier
    HAVING
        COUNT(i.i_item_id) > 5
)
SELECT
    a.i_category,
    a.i_category_id,
    a.sm_carrier,
    a.distinct_item_cnt,
    a.total_wholesale_cost,
    a.avg_current_price,
    a.min_current_price,
    a.max_current_price,
    a.avg_price_margin,
    RANK() OVER (ORDER BY a.total_wholesale_cost DESC) AS wholesale_cost_rank
FROM agg a
ORDER BY a.total_wholesale_cost DESC
LIMIT 100
