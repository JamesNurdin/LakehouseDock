WITH brand_carrier_agg AS (
    SELECT
        i.i_brand AS brand,
        sm.sm_carrier AS carrier,
        COUNT(*) AS item_count,
        SUM(i.i_current_price) AS total_current_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        MIN(i.i_rec_start_date) AS earliest_start_date,
        MAX(i.i_rec_end_date) AS latest_end_date
    FROM item i
    JOIN ship_mode sm ON i.i_manager_id = sm.sm_ship_mode_sk
    JOIN time_dim t ON i.i_item_sk = t.t_time_sk
    WHERE i.i_current_price > 5.00
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 8 AND 17
    GROUP BY i.i_brand, sm.sm_carrier
    HAVING COUNT(*) >= 5
)
SELECT
    brand,
    carrier,
    item_count,
    total_current_price,
    avg_wholesale_cost,
    earliest_start_date,
    latest_end_date,
    RANK() OVER (ORDER BY total_current_price DESC) AS price_rank
FROM brand_carrier_agg
ORDER BY total_current_price DESC
LIMIT 10
