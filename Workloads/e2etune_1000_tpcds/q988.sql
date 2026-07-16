WITH agg AS (
    SELECT
        i.i_class_id,
        ib.ib_income_band_sk,
        sm.sm_type,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        SUM(i.i_current_price) AS total_current_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost
    FROM
        item i
    JOIN
        income_band ib
        ON i.i_current_price >= ib.ib_lower_bound AND i.i_current_price < ib.ib_upper_bound
    JOIN
        ship_mode sm
        ON i.i_units = sm.sm_ship_mode_id
    WHERE
        i.i_rec_end_date >= DATE '1999-01-01' AND i.i_rec_end_date < DATE '2002-01-01'
        AND i.i_category_id IN (1, 2, 3, 4, 5)
    GROUP BY
        i.i_class_id,
        ib.ib_income_band_sk,
        sm.sm_type
    HAVING
        SUM(i.i_current_price) > 1000
)
SELECT
    i_class_id,
    ib_income_band_sk,
    sm_type,
    distinct_items,
    total_current_price,
    avg_wholesale_cost,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_current_price DESC) AS price_rank
FROM agg
ORDER BY ib_income_band_sk, price_rank
