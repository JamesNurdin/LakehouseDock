WITH
    joined_data AS (
        SELECT
            wr.wr_reason_sk,
            r.r_reason_desc,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_return_ship_cost,
            wr.wr_net_loss,
            t.t_hour,
            t.t_meal_time,
            map(
                ARRAY['quantity','amount'],
                ARRAY[cast(wr.wr_return_quantity AS double), cast(wr.wr_return_amt AS double)]
            ) AS metric_map
        FROM
            web_returns wr
            INNER JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
            INNER JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE
            t.t_hour BETWEEN 8 AND 18
            AND t.t_meal_time = 'Dinner'
            AND r.r_reason_desc LIKE '%Warranty%'
            AND wr.wr_return_quantity > 1
            AND wr.wr_return_tax > 0
            AND wr.wr_return_amt_inc_tax < 1000
    ),
    unnested_metrics AS (
        SELECT
            jd.r_reason_desc,
            m.key AS metric_name,
            m.value AS metric_value
        FROM
            joined_data jd
            CROSS JOIN UNNEST(jd.metric_map) AS m (key, value)
    ),
    metric_agg AS (
        SELECT
            r_reason_desc,
            metric_name,
            SUM(metric_value) AS metric_total
        FROM
            unnested_metrics
        GROUP BY
            r_reason_desc,
            metric_name
    ),
    metric_pivot AS (
        SELECT
            r_reason_desc,
            MAX(CASE WHEN metric_name = 'quantity' THEN metric_total END) AS metric_quantity_total,
            MAX(CASE WHEN metric_name = 'amount' THEN metric_total END) AS metric_amount_total
        FROM metric_agg
        GROUP BY r_reason_desc
    ),
    hour_agg AS (
        SELECT
            r_reason_desc,
            CAST(t_hour AS integer) AS hour,
            SUM(wr_return_quantity) AS total_quantity,
            SUM(wr_net_loss) AS total_net_loss,
            CASE WHEN SUM(wr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category,
            'hour' AS group_dim
        FROM joined_data
        GROUP BY r_reason_desc, t_hour
    ),
    meal_agg AS (
        SELECT
            r_reason_desc,
            t_meal_time,
            SUM(wr_return_quantity) AS total_quantity,
            SUM(wr_net_loss) AS total_net_loss,
            CASE WHEN SUM(wr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category,
            'meal' AS group_dim
        FROM joined_data
        GROUP BY r_reason_desc, t_meal_time
    ),
    combined_agg AS (
        SELECT
            r_reason_desc,
            CAST(hour AS varchar) AS group_key,
            total_quantity,
            total_net_loss,
            loss_category,
            group_dim
        FROM hour_agg
        UNION ALL
        SELECT
            r_reason_desc,
            t_meal_time AS group_key,
            total_quantity,
            total_net_loss,
            loss_category,
            group_dim
        FROM meal_agg
    ),
    final_agg AS (
        SELECT
            ca.r_reason_desc,
            ca.group_dim,
            AVG(ca.total_net_loss) AS avg_net_loss,
            SUM(ca.total_quantity) AS sum_quantity,
            COUNT(*) AS group_count,
            mp.metric_quantity_total,
            mp.metric_amount_total
        FROM combined_agg ca
        LEFT JOIN metric_pivot mp ON ca.r_reason_desc = mp.r_reason_desc
        GROUP BY
            ca.r_reason_desc,
            ca.group_dim,
            mp.metric_quantity_total,
            mp.metric_amount_total
        HAVING SUM(ca.total_quantity) > 10
    )
SELECT
    r_reason_desc,
    group_dim,
    avg_net_loss,
    sum_quantity,
    group_count,
    metric_quantity_total,
    metric_amount_total
FROM final_agg
ORDER BY avg_net_loss DESC
LIMIT 100
