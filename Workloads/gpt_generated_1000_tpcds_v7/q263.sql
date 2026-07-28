WITH sales AS (
  SELECT
    d.d_fy_week_seq,
    ca.ca_city,
    substring(d.d_date_id, 1, 5) AS date_prefix,
    SUM(ss.ss_net_profit) AS total_net_profit
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '^San')
    AND ca.ca_zip LIKE '9%'
    AND d.d_date_id LIKE 'AAAAAAA%'
  GROUP BY d.d_fy_week_seq, ca.ca_city, substring(d.d_date_id, 1, 5)
),
returns AS (
  SELECT
    d.d_fy_week_seq,
    ca.ca_city,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '^San')
    AND regexp_extract(ca.ca_zip, '(\\d{3})') = '941'
  GROUP BY d.d_fy_week_seq, ca.ca_city
)
SELECT
  s.d_fy_week_seq,
  s.ca_city,
  s.date_prefix,
  concat(s.ca_city, '-', s.date_prefix) AS city_week_key,
  s.total_net_profit,
  coalesce(r.total_net_loss, 0) AS total_net_loss
FROM sales s
LEFT JOIN returns r
  ON s.d_fy_week_seq = r.d_fy_week_seq
  AND s.ca_city = r.ca_city
ORDER BY s.total_net_profit DESC
LIMIT 100
