WITH unioned AS (
    SELECT
        'catalog' AS source_type,
        cr.cr_warehouse_sk AS grp_key,
        cr.cr_net_loss AS net_loss,
        td.t_meal_time,
        cd_ret.cd_education_status,
        td.t_hour
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    WHERE td.t_meal_time = 'lunch'
      AND cd_ret.cd_education_status = 'Advanced Degree'
      AND cr.cr_warehouse_sk IN (7, 13)
      AND td.t_hour BETWEEN 10 AND 14

    UNION ALL

    SELECT
        'web' AS source_type,
        wp.wp_web_page_sk AS grp_key,
        wr.wr_net_loss AS net_loss,
        td.t_meal_time,
        cd_ret.cd_education_status,
        td.t_hour
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_meal_time = 'lunch'
      AND cd_ret.cd_education_status = 'Advanced Degree'
      AND wp.wp_type = 'article'
      AND wr.wr_return_quantity > 1
),
agg AS (
    SELECT
        source_type,
        grp_key,
        SUM(net_loss) AS sum_net_loss,
        AVG(net_loss) AS avg_net_loss
    FROM unioned
    GROUP BY source_type, grp_key
    HAVING SUM(net_loss) > 0
)
SELECT
    source_type,
    grp_key,
    sum_net_loss,
    avg_net_loss,
    RANK() OVER (PARTITION BY source_type ORDER BY sum_net_loss DESC) AS rank_within_type
FROM agg
ORDER BY sum_net_loss DESC
LIMIT 100
