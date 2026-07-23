WITH store_sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    d.d_quarter_name,
    ca.ca_city AS city_name,
    ca.ca_zip,
    CONCAT(ca.ca_city, ' ', ca.ca_zip) AS city_zip,
    SUBSTRING(ca.ca_address_id, 1, 8) AS addr_prefix,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_city, '^[A-M].*')
    AND ca.ca_zip LIKE '9%'
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_quarter_name, ca.ca_city, ca.ca_zip, ca.ca_address_id
  HAVING SUM(ss.ss_ext_sales_price) > 50000
),
store_returns_agg AS (
  SELECT
    s.s_store_sk,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(*) AS return_cnt,
    COUNT(DISTINCT CASE WHEN regexp_like(r.r_reason_desc, '.*damage.*') THEN sr.sr_ticket_number END) AS damage_return_cnt,
    REGEXP_EXTRACT(MIN(r.r_reason_desc), '^\\w+') AS first_word_of_reason
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  GROUP BY s.s_store_sk, d.d_year
)
SELECT
  ss.s_store_name,
  ss.d_year,
  ss.d_quarter_name,
  ss.city_name,
  ss.city_zip,
  ss.addr_prefix,
  ss.total_sales,
  ss.total_net_profit,
  COALESCE(sr.total_return_loss, 0) AS total_return_loss,
  COALESCE(sr.return_cnt, 0) AS return_cnt,
  CASE
    WHEN ss.total_net_profit - COALESCE(sr.total_return_loss, 0) > 10000 THEN 'High'
    ELSE 'Low'
  END AS profit_category,
  COALESCE(sr.damage_return_cnt, 0) AS damage_return_cnt,
  sr.first_word_of_reason
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr
  ON ss.s_store_sk = sr.s_store_sk
  AND ss.d_year = sr.d_year
ORDER BY ss.total_net_profit DESC
LIMIT 100
