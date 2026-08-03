WITH catalog_agg AS (
    SELECT
        i.i_brand,
        w.w_state,
        t.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_quantity) AS total_qty,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_ship_cost > 1000
      AND i.i_current_price < 500
      AND w.w_state = 'CA'
    GROUP BY i.i_brand, w.w_state, t.t_hour
),
web_agg AS (
    SELECT
        i.i_brand,
        NULL AS w_state,
        t.t_hour,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_quantity) AS total_qty,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_amt > 500
      AND i.i_current_price < 500
      AND t.t_am_pm = 'PM'
    GROUP BY i.i_brand, t.t_hour
),
union_agg AS (
    SELECT i_brand, w_state, t_hour,
           total_return_amount,
           distinct_orders,
           total_qty,
           avg_ship_cost
    FROM catalog_agg
    UNION DISTINCT
    SELECT i_brand, w_state, t_hour,
           total_return_amount,
           distinct_orders,
           total_qty,
           avg_ship_cost
    FROM web_agg
),
final_agg AS (
    SELECT
        i_brand,
        COALESCE(w_state, 'UNKNOWN') AS state,
        t_hour,
        SUM(total_return_amount) AS sum_return_amount,
        COUNT(DISTINCT distinct_orders) AS distinct_order_cnt,
        SUM(total_qty) AS sum_qty,
        AVG(avg_ship_cost) AS avg_ship_cost_over_groups,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY SUM(total_return_amount) DESC) AS brand_rank,
        COUNT(DISTINCT i_brand) OVER () AS total_brands
    FROM union_agg
    GROUP BY i_brand, COALESCE(w_state, 'UNKNOWN'), t_hour
    HAVING SUM(total_return_amount) > 10000
),
order_numbers_excluded AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
)
SELECT
    f.i_brand,
    f.state,
    f.t_hour,
    f.sum_return_amount,
    f.distinct_order_cnt,
    f.sum_qty,
    f.avg_ship_cost_over_groups,
    f.brand_rank,
    f.total_brands,
    (SELECT COUNT(*) FROM order_numbers_excluded) AS excluded_order_cnt
FROM final_agg f
WHERE f.brand_rank <= 10
ORDER BY f.sum_return_amount DESC
LIMIT 100
