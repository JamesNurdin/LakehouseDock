WITH filtered_returns AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_customer_sk,
    sr.sr_addr_sk,
    sr.sr_reason_sk,
    sr.sr_net_loss,
    c.c_customer_id,
    c.c_email_address,
    ca.ca_city AS ca_city,
    r.r_reason_desc,
    regexp_extract(c.c_email_address, '([^@]+)@', 1) AS email_user,
    substring(c.c_last_name, 1, 1) AS last_initial
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE regexp_like(c.c_email_address, '.*@example\\.com$')
    AND ca.ca_city LIKE '%York%'
),
agg AS (
  SELECT
    r_reason_desc,
    ca_city,
    COUNT(*) AS returns_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_net_loss) AS avg_net_loss,
    MIN(email_user) AS sample_email_user,
    MAX(last_initial) AS sample_last_initial
  FROM filtered_returns
  GROUP BY r_reason_desc, ca_city
)
SELECT
  r_reason_desc,
  ca_city,
  returns_cnt,
  total_net_loss,
  avg_net_loss,
  ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS reason_city_rank,
  sample_email_user,
  sample_last_initial
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
