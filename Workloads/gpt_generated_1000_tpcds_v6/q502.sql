WITH time_filtered AS (
    SELECT t_time_sk, t_hour, t_sub_shift
    FROM time_dim
    WHERE t_sub_shift IN ('morning', 'night')
)
SELECT
    hour,
    shift,
    total_net_paid_inc_tax,
    total_discount_amt
FROM (
    SELECT
        tf.t_hour AS hour,
        tf.t_sub_shift AS shift,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amt
    FROM catalog_sales cs
    JOIN time_filtered tf
        ON cs.cs_sold_time_sk = tf.t_time_sk
    WHERE tf.t_sub_shift = 'morning'
      AND cs.cs_net_paid_inc_tax > 300
    GROUP BY tf.t_hour, tf.t_sub_shift

    UNION ALL

    SELECT
        tf.t_hour AS hour,
        tf.t_sub_shift AS shift,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amt
    FROM catalog_sales cs
    JOIN time_filtered tf
        ON cs.cs_sold_time_sk = tf.t_time_sk
    WHERE tf.t_sub_shift = 'night'
      AND cs.cs_net_paid_inc_tax > 300
    GROUP BY tf.t_hour, tf.t_sub_shift
) AS combined
ORDER BY hour, shift, total_net_paid_inc_tax DESC
LIMIT 100
