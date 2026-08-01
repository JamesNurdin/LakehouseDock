WITH filtered_returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_returned_time_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_quantity >= 1
      AND wr.wr_return_amt > 10.0
      AND wr.wr_return_tax < 5.0
      AND wr.wr_fee BETWEEN 0 AND 50
      AND wr.wr_reversed_charge <> 0
      AND wr.wr_account_credit > 20
),
refunded_orders AS (
    SELECT wr_order_number FROM filtered_returns
),
high_loss_orders AS (
    SELECT wr_order_number FROM filtered_returns WHERE wr_net_loss > 100
),
valid_orders AS (
    SELECT wr_order_number FROM refunded_orders
    EXCEPT
    SELECT wr_order_number FROM high_loss_orders
),
returns_with_array AS (
    SELECT
        fr.wr_order_number,
        fr.wr_returned_time_sk,
        fr.wr_refunded_cdemo_sk,
        fr.wr_return_quantity,
        fr.wr_return_amt,
        fr.wr_return_tax,
        fr.wr_return_amt_inc_tax,
        fr.wr_fee,
        fr.wr_return_ship_cost,
        fr.wr_refunded_cash,
        fr.wr_reversed_charge,
        fr.wr_account_credit,
        fr.wr_net_loss,
        ARRAY[fr.wr_return_amt, fr.wr_return_tax] AS amt_tax_array
    FROM filtered_returns fr
),
unnested_returns AS (
    SELECT
        rwa.wr_order_number,
        rwa.wr_returned_time_sk,
        rwa.wr_refunded_cdemo_sk,
        rwa.wr_return_quantity,
        rwa.wr_return_amt,
        rwa.wr_return_tax,
        rwa.wr_return_amt_inc_tax,
        rwa.wr_fee,
        rwa.wr_return_ship_cost,
        rwa.wr_refunded_cash,
        rwa.wr_reversed_charge,
        rwa.wr_account_credit,
        rwa.wr_net_loss,
        u.val AS metric_value,
        CASE WHEN u.ordinality = 1 THEN 'return_amt' ELSE 'return_tax' END AS metric_type
    FROM returns_with_array rwa
    CROSS JOIN UNNEST(rwa.amt_tax_array) WITH ORDINALITY AS u(val, ordinality)
),
full_time_join AS (
    SELECT
        ur.wr_order_number,
        ur.wr_returned_time_sk,
        ur.wr_refunded_cdemo_sk,
        ur.wr_return_quantity,
        ur.wr_return_amt,
        ur.wr_return_tax,
        ur.wr_return_amt_inc_tax,
        ur.wr_fee,
        ur.wr_return_ship_cost,
        ur.wr_refunded_cash,
        ur.wr_reversed_charge,
        ur.wr_account_credit,
        ur.wr_net_loss,
        ur.metric_value,
        ur.metric_type,
        td.t_time_id,
        td.t_hour,
        td.t_minute,
        td.t_second,
        td.t_am_pm,
        td.t_shift,
        td.t_sub_shift,
        td.t_meal_time
    FROM unnested_returns ur
    FULL OUTER JOIN time_dim td
        ON ur.wr_returned_time_sk = td.t_time_sk
),
final_join AS (
    SELECT
        ftj.wr_order_number,
        ftj.t_hour,
        ftj.metric_type,
        ftj.metric_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM full_time_join ftj
    JOIN customer_demographics cd
        ON ftj.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE ftj.wr_order_number IN (SELECT wr_order_number FROM valid_orders)
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_order_number = ftj.wr_order_number
            AND wr2.wr_return_quantity > 5
            AND wr2.wr_return_amt > 200
      )
)
SELECT
    cd_gender,
    cd_marital_status,
    t_hour,
    metric_type,
    COUNT(*) AS cnt_returns,
    SUM(metric_value) AS total_metric,
    AVG(metric_value) AS avg_metric,
    MIN(metric_value) AS min_metric,
    MAX(metric_value) AS max_metric
FROM final_join
GROUP BY cd_gender, cd_marital_status, t_hour, metric_type
HAVING COUNT(*) >= 1
ORDER BY total_metric DESC
OFFSET 10 LIMIT 100
