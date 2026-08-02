WITH agg_returns AS (
    SELECT
        cr_call_center_sk,
        cr_returned_time_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        AVG(cr_reversed_charge) AS avg_reversed_charge,
        MAX(cr_return_amount) AS max_return_amount,
        COUNT(DISTINCT cr_order_number) AS distinct_orders
    FROM catalog_returns
    WHERE cr_reversed_charge > 100
      AND cr_return_quantity > 1
      AND cr_return_amount > 0
      AND cr_call_center_sk IS NOT NULL
      AND cr_returned_time_sk IS NOT NULL
      AND cr_returned_date_sk >= 2450000
    GROUP BY cr_call_center_sk, cr_returned_time_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_manager,
    cc.cc_city,
    td.t_time_id,
    td.t_meal_time,
    td.t_am_pm,
    agg.total_return_amount,
    agg.total_return_quantity,
    agg.avg_reversed_charge,
    agg.max_return_amount,
    agg.distinct_orders,
    CASE
        WHEN agg.total_return_amount > 10000 THEN 'HIGH'
        WHEN agg.total_return_amount BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY agg.total_return_amount DESC) AS rn_by_center,
    RANK() OVER (PARTITION BY td.t_meal_time ORDER BY agg.total_return_quantity DESC) AS qty_rank_by_meal
FROM agg_returns agg
INNER JOIN call_center cc
    ON agg.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN time_dim td
    ON agg.cr_returned_time_sk = td.t_time_sk
WHERE
    cc.cc_manager = 'Ronnie Trinidad'
    AND cc.cc_street_number = '999'
    AND cc.cc_mkt_class = 'Major'
    AND td.t_meal_time IN ('dinner', 'lunch')
    AND td.t_am_pm = 'PM'
    AND cc.cc_state = 'CA'
LIMIT 100
