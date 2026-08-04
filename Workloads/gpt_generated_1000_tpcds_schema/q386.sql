WITH joined_data AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_returned_time_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       t.t_hour,
       t.t_minute,
       t.t_sub_shift,
       ARRAY[cr.cr_return_quantity, CAST(cr.cr_return_amount AS double)] AS metrics_array,
       MAP(ARRAY['quantity','amount'], ARRAY[cr.cr_return_quantity, CAST(cr.cr_return_amount AS double)]) AS metrics_map
   FROM catalog_returns cr
   FULL OUTER JOIN time_dim t
       ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE (t.t_sub_shift = 'evening' OR t.t_sub_shift IS NULL)
     AND (cr.cr_return_quantity IS NOT NULL AND cr.cr_return_quantity > 0)
)
SELECT
    jd.cr_returned_date_sk,
    jd.t_hour,
    metric,
    'array' AS metric_source
FROM joined_data jd
CROSS JOIN UNNEST(jd.metrics_array) AS u(metric)
UNION ALL
SELECT
    jd.cr_returned_date_sk,
    jd.t_hour,
    metric,
    CONCAT('map_', metric_key) AS metric_source
FROM joined_data jd
CROSS JOIN UNNEST(jd.metrics_map) AS m(metric_key, metric)
ORDER BY cr_returned_date_sk ASC, metric DESC
OFFSET 0
LIMIT 100
