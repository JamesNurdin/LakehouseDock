WITH store_agg AS (
  SELECT
    ca.ca_county,
    ca.ca_street_type,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS store_txn_count
  FROM store_sales ss
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
    AND ca.ca_country = 'United States'
    AND ca.ca_street_type IN ('Rd', 'Blvd', 'Parkway')
  GROUP BY ca.ca_county, ca.ca_street_type
),
return_agg AS (
  SELECT
    ca.ca_county,
    ca.ca_street_type,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_txn_count
  FROM web_returns wr
  JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    AND ca.ca_country = 'United States'
    AND ca.ca_street_type IN ('Rd', 'Blvd', 'Parkway')
  GROUP BY ca.ca_county, ca.ca_street_type
)
SELECT
  COALESCE(sa.ca_county, ra.ca_county) AS county,
  COALESCE(sa.ca_street_type, ra.ca_street_type) AS street_type,
  COALESCE(sa.total_store_profit, 0) AS store_profit,
  COALESCE(ra.total_return_loss, 0) AS return_loss,
  COALESCE(sa.total_store_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_contribution,
  COALESCE(sa.store_txn_count, 0) AS store_txn_cnt,
  COALESCE(ra.return_txn_count, 0) AS return_txn_cnt,
  CASE WHEN COALESCE(sa.total_sales, 0) > 0 THEN COALESCE(sa.total_store_profit, 0) / COALESCE(sa.total_sales, 1) ELSE NULL END AS store_profit_margin,
  CASE WHEN COALESCE(ra.total_return_amount, 0) > 0 THEN COALESCE(ra.total_return_loss, 0) / COALESCE(ra.total_return_amount, 1) ELSE NULL END AS return_loss_rate,
  RANK() OVER (ORDER BY COALESCE(sa.total_store_profit, 0) - COALESCE(ra.total_return_loss, 0) DESC) AS profit_rank
FROM store_agg sa
FULL OUTER JOIN return_agg ra
  ON sa.ca_county = ra.ca_county
  AND sa.ca_street_type = ra.ca_street_type
WHERE COALESCE(sa.total_store_profit, 0) - COALESCE(ra.total_return_loss, 0) > 0
ORDER BY net_contribution DESC
LIMIT 20
