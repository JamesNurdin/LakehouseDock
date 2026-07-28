WITH cat AS (
  SELECT
    d.d_quarter_seq,
    SUM(cr.cr_net_loss) AS catalog_loss
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE regexp_like(d.d_day_name, '^S')
  GROUP BY d.d_quarter_seq
),
web AS (
  SELECT
    d.d_quarter_seq,
    SUM(wr.wr_net_loss) AS web_loss
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  WHERE ws.web_name LIKE '%Shop%'
    AND substring(ws.web_name, 1, 1) = 'W'
    AND regexp_like(d.d_day_name, '^S')
  GROUP BY d.d_quarter_seq
)
SELECT
  concat('Q', CAST(COALESCE(cat.d_quarter_seq, web.d_quarter_seq) AS VARCHAR)) AS quarter_label,
  COALESCE(cat.catalog_loss, 0) AS catalog_loss,
  COALESCE(web.web_loss, 0) AS web_loss,
  COALESCE(cat.catalog_loss, 0) + COALESCE(web.web_loss, 0) AS total_net_loss
FROM cat
FULL OUTER JOIN web
  ON cat.d_quarter_seq = web.d_quarter_seq
ORDER BY quarter_label
