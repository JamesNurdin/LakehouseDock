WITH item_warehouse_returns_agg AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_refunded_customer_sk,
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY
        cr_item_sk,
        cr_warehouse_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_refunded_customer_sk,
        cr_returning_customer_sk
),
joined_data AS (
    SELECT
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        i.i_item_id,
        i.i_class,
        i.i_class_id,
        td.t_hour,
        td.t_am_pm,
        c_ref.c_first_name || ' ' || c_ref.c_last_name AS refunded_customer_name,
        c_ret.c_first_name || ' ' || c_ret.c_last_name AS returning_customer_name,
        agg.total_return_qty,
        agg.total_return_amount,
        agg.total_net_loss,
        CASE
            WHEN agg.total_return_amount > 5000 THEN 'High'
            WHEN agg.total_return_amount > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS return_amount_category
    FROM item_warehouse_returns_agg agg
    INNER JOIN item i ON agg.cr_item_sk = i.i_item_sk
    INNER JOIN warehouse w ON agg.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN time_dim td ON agg.cr_returned_time_sk = td.t_time_sk
    INNER JOIN call_center cc ON agg.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN customer c_ref ON agg.cr_refunded_customer_sk = c_ref.c_customer_sk
    INNER JOIN customer c_ret ON agg.cr_returning_customer_sk = c_ret.c_customer_sk
    WHERE
        i.i_class_id IN (1, 7, 13)
        AND i.i_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND td.t_am_pm = 'PM'
        AND w.w_city IN ('Greenwood', 'Salem')
)
SELECT
    call_center_name,
    warehouse_name,
    i_class_id,
    SUM(total_return_qty) AS sum_return_qty,
    SUM(total_return_amount) AS sum_return_amount,
    AVG(total_net_loss) AS avg_net_loss,
    COUNT(*) AS num_groups,
    CASE
        WHEN SUM(total_return_amount) > 20000 THEN 'Very High'
        ELSE 'Normal'
    END AS overall_return_category
FROM joined_data
WHERE return_amount_category = 'High'
GROUP BY
    call_center_name,
    warehouse_name,
    i_class_id
HAVING SUM(total_return_qty) > 10
ORDER BY sum_return_amount DESC
LIMIT 100
