WITH
  refunds AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_year,
      cr.cr_return_amount,
      cr.cr_net_loss,
      c.c_customer_id,
      cd.cd_credit_rating,
      r.r_reason_desc,
      regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_first_word,
      CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 1 ELSE 0 END AS is_damaged
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 0
  ),
  sites AS (
    SELECT
      ws.web_site_id,
      ws.web_name,
      ws.web_gmt_offset,
      d.d_year,
      substr(ws.web_name, 1, 5) AS name_prefix,
      CASE WHEN ws.web_name LIKE '%Web%' THEN 1 ELSE 0 END AS is_web_name,
      lt.extracted_num
    FROM web_site ws
    JOIN date_dim d
      ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
      SELECT regexp_extract(ws.web_name, '(\\d+)', 1) AS extracted_num
    ) lt ON true
    WHERE ws.web_gmt_offset IS NOT NULL
  ),
  combined AS (
    SELECT
      r.d_year,
      r.cd_credit_rating,
      r.is_damaged,
      r.reason_first_word,
      SUM(r.cr_return_amount) AS total_return_amount,
      SUM(r.cr_net_loss) AS total_net_loss,
      NULL AS web_name,
      NULL AS web_gmt_offset
    FROM refunds r
    GROUP BY r.d_year, r.cd_credit_rating, r.is_damaged, r.reason_first_word

    UNION DISTINCT

    SELECT
      s.d_year,
      NULL AS cd_credit_rating,
      NULL AS is_damaged,
      NULL AS reason_first_word,
      NULL AS total_return_amount,
      NULL AS total_net_loss,
      s.web_name,
      s.web_gmt_offset
    FROM sites s
  )
SELECT
  c.d_year,
  c.cd_credit_rating,
  c.is_damaged,
  c.reason_first_word,
  c.total_return_amount,
  c.total_net_loss,
  c.web_name,
  c.web_gmt_offset,
  sc.site_count
FROM combined c
FULL OUTER JOIN (
  SELECT d_year, COUNT(*) AS site_count
  FROM sites
  GROUP BY d_year
) sc
  ON c.d_year = sc.d_year
ORDER BY c.d_year DESC NULLS LAST,
         c.total_return_amount DESC NULLS LAST
LIMIT 100
