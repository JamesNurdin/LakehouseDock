WITH reason_word_cte AS (
   SELECT r_reason_sk,
          regexp_extract(r_reason_desc, '(\\w+)', 1) AS reason_word
   FROM reason
   WHERE regexp_like(r_reason_desc, '(?i)defect')
),
web_src AS (
   SELECT d.d_year AS year,
          rw.reason_word,
          SUM(wr.wr_net_loss) AS net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason_word_cte rw ON wr.wr_reason_sk = rw.r_reason_sk
   GROUP BY GROUPING SETS ((d.d_year, rw.reason_word),
                           (d.d_year),
                           ())
),
catalog_src AS (
   SELECT d.d_year AS year,
          rw.reason_word,
          SUM(cr.cr_net_loss) AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason_word_cte rw ON cr.cr_reason_sk = rw.r_reason_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_name LIKE 'Call%'
   GROUP BY GROUPING SETS ((d.d_year, rw.reason_word),
                           (d.d_year),
                           ())
),
combined AS (
   SELECT * FROM web_src
   UNION ALL
   SELECT * FROM catalog_src
),
final_agg AS (
   SELECT year,
          reason_word,
          SUM(net_loss) AS total_net_loss
   FROM combined
   GROUP BY ROLLUP (year, reason_word)
)
SELECT year,
       reason_word,
       total_net_loss,
       CONCAT(CAST(year AS varchar), '-', COALESCE(reason_word, 'ALL')) AS label
FROM final_agg
ORDER BY year DESC NULLS LAST, reason_word
LIMIT 100
