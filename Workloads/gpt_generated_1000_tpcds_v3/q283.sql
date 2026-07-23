WITH site_sales AS (
  SELECT
    ws.ws_web_site_sk,
    td.t_sub_shift,
    wsit.web_name,
    wsit.web_site_id,
    CONCAT(wsit.web_name, ' - ', td.t_sub_shift) AS site_shift_label,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE regexp_like(td.t_time_id, '^AAAAAAA[DE]')
    AND wsit.web_name LIKE '%Market%'
    AND wsit.web_class LIKE 'A%'
  GROUP BY ws.ws_web_site_sk,
           td.t_sub_shift,
           wsit.web_name,
           wsit.web_site_id,
           CONCAT(wsit.web_name, ' - ', td.t_sub_shift)
),
shift_returns AS (
  SELECT
    td.t_sub_shift,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  WHERE regexp_like(td.t_time_id, '^AAAAAAA[DE]')
  GROUP BY td.t_sub_shift
)
SELECT
  ss.site_shift_label AS site_shift,
  ss.total_net_paid,
  ss.sales_cnt,
  COALESCE(sr.total_return_amount, 0) AS total_return_amount,
  ss.total_net_paid - COALESCE(sr.total_return_amount, 0) AS net_profit_adjusted,
  substring(ss.web_name, 1, 5) AS name_prefix,
  regexp_extract(ss.web_site_id, '([A-Z]+)') AS site_alpha,
  (ss.total_net_paid - COALESCE(sr.total_return_amount, 0)) / (
    SELECT SUM(ws2.ws_net_paid_inc_ship)
    FROM web_sales ws2
    JOIN time_dim td2 ON ws2.ws_sold_time_sk = td2.t_time_sk
    JOIN web_site wsit2 ON ws2.ws_web_site_sk = wsit2.web_site_sk
    WHERE regexp_like(td2.t_time_id, '^AAAAAAA[DE]')
      AND wsit2.web_name LIKE '%Market%'
      AND wsit2.web_class LIKE 'A%'
  ) AS profit_share_of_total
FROM site_sales ss
LEFT JOIN shift_returns sr
  ON ss.t_sub_shift = sr.t_sub_shift
ORDER BY net_profit_adjusted DESC
LIMIT 10
