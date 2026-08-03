WITH store_agg AS (
  SELECT
    s.s_store_sk,
    s.s_state,
    s.s_store_name,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(sr.sr_net_loss) DESC) AS rnk,
    LAG(SUM(sr.sr_net_loss)) OVER (PARTITION BY s.s_state ORDER BY d.d_year) AS prev_year_loss
  FROM store_returns sr
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)damage')
    AND s.s_store_name LIKE 'A%'
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY s.s_store_sk, s.s_state, s.s_store_name, d.d_year
  HAVING SUM(sr.sr_net_loss) > 0
),
web_agg AS (
  SELECT
    w.web_site_sk,
    w.web_name,
    w.web_city,
    d.d_year,
    SUM(wr.wr_net_loss) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY w.web_city ORDER BY SUM(wr.wr_net_loss) DESC) AS rnk,
    LAG(SUM(wr.wr_net_loss)) OVER (PARTITION BY w.web_city ORDER BY d.d_year) AS prev_year_loss
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
  JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc LIKE '%customer%'
    AND regexp_extract(w.web_name, '^([A-Z]{3})', 1) = 'WEB'
    AND d.d_year = 2001
  GROUP BY w.web_site_sk, w.web_name, w.web_city, d.d_year
  HAVING SUM(wr.wr_net_loss) > 0
)
SELECT *
FROM (
  SELECT
    'store' AS entity_type,
    s.s_store_name AS entity_name,
    s.d_year,
    s.total_loss,
    s.prev_year_loss,
    s.rnk,
    s.total_loss / (SELECT SUM(total_loss) FROM store_agg) AS loss_ratio
  FROM store_agg s
  WHERE s.rnk <= 5

  UNION DISTINCT

  SELECT
    'web' AS entity_type,
    w.web_name AS entity_name,
    w.d_year,
    w.total_loss,
    w.prev_year_loss,
    w.rnk,
    w.total_loss / (SELECT SUM(total_loss) FROM web_agg) AS loss_ratio
  FROM web_agg w
  WHERE w.rnk <= 5
) t
ORDER BY entity_type, total_loss DESC
LIMIT 100
