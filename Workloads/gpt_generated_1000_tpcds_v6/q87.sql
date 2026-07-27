WITH combined AS (
  SELECT
    d.d_year,
    ca.ca_state,
    sr.sr_store_sk,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca
    ON ca.ca_address_sk = sr.sr_addr_sk
  WHERE d.d_year = 2001
    AND ca.ca_country = 'United States'
    AND ca.ca_state = 'CA'
    AND sr.sr_return_tax > 2.0
    AND cr.cr_return_amount > 100.00
    AND d.d_current_quarter = 'Y'
  GROUP BY d.d_year, ca.ca_state, sr.sr_store_sk
)
SELECT
  d_year,
  AVG(total_net_loss) AS avg_total_net_loss,
  SUM(total_returns) AS sum_returns
FROM combined
GROUP BY d_year
HAVING AVG(total_net_loss) > 500.00
ORDER BY avg_total_net_loss DESC
LIMIT 100
