WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        t.t_meal_time,
        cd_ref.cd_gender AS refunded_gender,
        cd_ref.cd_marital_status AS refunded_marital_status,
        cd_ret.cd_gender AS returning_gender,
        cd_ret.cd_education_status AS returning_education_status,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_market_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2022
      AND s.s_market_desc IN ('Online', 'Retail')
      AND t.t_meal_time = 'Dinner'
),
agg_data AS (
    SELECT
        s_store_name,
        s_city,
        s_state,
        d_year,
        s_market_desc,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT cr_order_number) AS num_orders,
        COUNT_IF(refunded_gender = 'F') AS female_refunded_count,
        COUNT_IF(returning_gender = 'M') AS male_returning_count,
        MAX(cr_net_loss) AS max_net_loss,
        MIN(cr_net_loss) AS min_net_loss,
        CASE WHEN SUM(cr_return_quantity) > 0 THEN SUM(cr_net_loss) / SUM(cr_return_quantity) ELSE NULL END AS net_loss_per_item
    FROM joined_data
    GROUP BY s_store_name, s_city, s_state, d_year, s_market_desc
)
SELECT
    s_store_name,
    s_city,
    s_state,
    d_year,
    s_market_desc,
    total_return_amount,
    avg_return_quantity,
    num_orders,
    female_refunded_count,
    male_returning_count,
    max_net_loss,
    min_net_loss,
    net_loss_per_item,
    RANK() OVER (ORDER BY total_return_amount DESC) AS store_return_rank
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 50
