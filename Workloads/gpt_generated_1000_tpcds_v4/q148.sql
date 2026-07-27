WITH sales_returns AS (
  SELECT
    s.s_store_name,
    ca.ca_city,
    ca.ca_street_name,
    regexp_extract(ca.ca_street_name, '(\\d+)', 1) AS street_number_extracted,
    r.r_reason_desc,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr
    ON ca.ca_address_sk = wr.wr_returning_addr_sk
  LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE
    regexp_like(ca.ca_street_name, '\\d')
    AND ca.ca_city LIKE 'San%'
    AND (r.r_reason_desc IS NULL OR regexp_like(r.r_reason_desc, '(?i)damage|defect'))
  GROUP BY
    s.s_store_name,
    ca.ca_city,
    ca.ca_street_name,
    regexp_extract(ca.ca_street_name, '(\\d+)', 1),
    r.r_reason_desc
)
SELECT DISTINCT
  s_store_name,
  ca_city,
  street_number_extracted,
  r_reason_desc,
  total_sales,
  total_profit,
  distinct_tickets,
  distinct_returns
FROM sales_returns
ORDER BY total_sales DESC
LIMIT 100
