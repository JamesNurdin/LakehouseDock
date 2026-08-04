WITH cc_expanded AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    d.d_year,
    cr.cr_net_loss,
    split(cc.cc_name, ' ') AS name_parts
  FROM call_center cc
  JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE cc.cc_name LIKE '%Center%'
    AND regexp_like(cc.cc_city, '^[A-Z][a-z]+$')
),

cc_unnested AS (
  SELECT
    ce.cc_call_center_sk,
    ce.cc_name,
    ce.cc_city,
    ce.d_year,
    ce.cr_net_loss,
    part AS name_word
  FROM cc_expanded ce
  CROSS JOIN UNNEST(ce.name_parts) AS t(part)
),

cc_agg AS (
  SELECT
    cn.cc_call_center_sk,
    cn.cc_name,
    cn.d_year,
    SUM(cn.cr_net_loss) AS total_net_loss,
    CASE
      WHEN SUM(cn.cr_net_loss) > 1000 THEN 'HIGH'
      WHEN SUM(cn.cr_net_loss) > 500  THEN 'MEDIUM'
      ELSE 'LOW'
    END AS loss_bucket
  FROM cc_unnested cn
  GROUP BY cn.cc_call_center_sk, cn.cc_name, cn.d_year
),

ws_agg AS (
  SELECT
    w.w_warehouse_sk,
    ws.ws_web_site_sk,
    d.d_year,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CASE
      WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH'
      WHEN SUM(ws.ws_net_profit) > 5000  THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_bucket,
    regexp_extract(ws_site.web_name, '(\\w+)', 1) AS site_first_word,
    substring(ws_site.web_name FROM 1 FOR 5) AS web_name_prefix
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ws_site.web_name LIKE '%Site%'
    AND regexp_like(ws_site.web_city, '^[A-Z].*')
  GROUP BY w.w_warehouse_sk, ws.ws_web_site_sk, d.d_year, ws_site.web_name
),

union_all AS (
  SELECT
    cc_agg.cc_call_center_sk AS key_id,
    cc_agg.cc_name AS name,
    cc_agg.d_year,
    cc_agg.total_net_loss AS metric,
    cc_agg.loss_bucket AS bucket,
    'CALL_CENTER' AS source
  FROM cc_agg
  UNION DISTINCT
  SELECT
    ws_agg.w_warehouse_sk AS key_id,
    ws_agg.site_first_word AS name,
    ws_agg.d_year,
    ws_agg.total_net_profit AS metric,
    ws_agg.profit_bucket AS bucket,
    'WAREHOUSE' AS source
  FROM ws_agg
),

common_years AS (
  SELECT d_year FROM cc_agg
  INTERSECT
  SELECT d_year FROM ws_agg
),

ranked AS (
  SELECT
    u.key_id,
    u.name,
    u.d_year,
    u.metric,
    u.bucket,
    u.source,
    ROW_NUMBER() OVER (PARTITION BY u.d_year ORDER BY u.metric DESC) AS rn
  FROM union_all u
  WHERE u.d_year IN (SELECT d_year FROM common_years)
)

SELECT
  key_id,
  name,
  d_year,
  metric,
  bucket,
  source
FROM ranked
WHERE rn <= 5
ORDER BY d_year DESC, metric DESC
LIMIT 100
