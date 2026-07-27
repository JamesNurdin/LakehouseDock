WITH returns_weekly AS (
   SELECT
       d.d_fy_week_seq AS week_seq,
       SUM(cr.cr_return_amount) AS total_return_amount,
       CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH_LOSS' ELSE 'LOW_LOSS' END AS loss_category,
       'RETURN' AS source
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND cr.cr_reason_sk IN (13, 45, 54)
   GROUP BY d.d_fy_week_seq
),
pages_weekly AS (
   SELECT
       d.d_fy_week_seq AS week_seq,
       SUM(wp.wp_link_count) AS total_link_count,
       CASE WHEN SUM(wp.wp_link_count) > 500 THEN 'HIGH_LINK' ELSE 'LOW_LINK' END AS loss_category,
       'PAGE' AS source
   FROM web_page wp
   JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND wp.wp_autogen_flag = 'N'
   GROUP BY d.d_fy_week_seq
),
combined AS (
   SELECT
       week_seq,
       total_return_amount,
       NULL AS total_link_count,
       loss_category,
       source
   FROM returns_weekly
   UNION ALL
   SELECT
       week_seq,
       NULL AS total_return_amount,
       total_link_count,
       loss_category,
       source
   FROM pages_weekly
)
SELECT
   week_seq,
   total_return_amount,
   total_link_count,
   loss_category,
   source,
   ROW_NUMBER() OVER (PARTITION BY source ORDER BY week_seq) AS row_num
FROM combined
ORDER BY source, row_num
LIMIT 100
