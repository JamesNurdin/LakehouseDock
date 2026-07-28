WITH catalog AS (
   SELECT
      cr.cr_returned_date_sk,
      cr.cr_net_loss AS cr_net_loss,
      r.r_reason_desc AS r_reason_desc,
      r.r_reason_id AS r_reason_id,
      regexp_extract(r.r_reason_id, '^(.{4})', 1) AS reason_prefix
   FROM tpcds.catalog_returns cr
   JOIN tpcds.reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN tpcds.date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND regexp_like(r.r_reason_desc, '(?i)did not')
),
web AS (
   SELECT
      wr.wr_returned_date_sk,
      wr.wr_net_loss AS wr_net_loss,
      r.r_reason_desc AS r_reason_desc,
      r.r_reason_id AS r_reason_id,
      regexp_extract(r.r_reason_id, '^(.{4})', 1) AS reason_prefix
   FROM tpcds.web_returns wr
   JOIN tpcds.reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN tpcds.date_dim d
     ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND regexp_like(r.r_reason_desc, '(?i)did not')
)
SELECT
   src.return_type,
   src.reason_prefix,
   src.r_reason_desc,
   SUM(src.net_loss) AS total_net_loss,
   COUNT(*) AS return_cnt,
   concat('Prefix-', src.reason_prefix) AS prefixed_label
FROM (
   SELECT 'catalog' AS return_type,
          cr_net_loss AS net_loss,
          r_reason_desc,
          reason_prefix
   FROM catalog
   UNION ALL
   SELECT 'web' AS return_type,
          wr_net_loss AS net_loss,
          r_reason_desc,
          reason_prefix
   FROM web
) src
WHERE src.r_reason_desc LIKE '%did not%'
GROUP BY src.return_type, src.reason_prefix, src.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 10
