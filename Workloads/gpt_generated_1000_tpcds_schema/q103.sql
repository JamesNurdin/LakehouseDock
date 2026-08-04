WITH only_catalog_customers AS (
   SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
   FROM catalog_returns cr
   JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
   WHERE d1.d_year = 2001
), only_web_customers AS (
   SELECT DISTINCT wr.wr_refunded_customer_sk AS customer_sk
   FROM web_returns wr
   JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
), catalog_not_web AS (
   SELECT customer_sk FROM only_catalog_customers
   EXCEPT
   SELECT customer_sk FROM only_web_customers
)
SELECT
   ss.ss_item_sk,
   ss.ss_customer_sk,
   d.d_year,
   ca.ca_state,
   cd.cd_gender,
   ss.ss_quantity,
   ss.ss_net_paid,
   ss.ss_net_profit,
   cr.cr_return_amount,
   wr.wr_return_amt,
   ws.web_name,
   ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ss.ss_net_profit DESC) AS profit_rank_state,
   CASE
      WHEN cr.cr_return_amount IS NOT NULL AND wr.wr_return_amt IS NOT NULL THEN 'Both Returns'
      WHEN cr.cr_return_amount IS NOT NULL THEN 'Catalog Return'
      WHEN wr.wr_return_amt IS NOT NULL THEN 'Web Return'
      ELSE 'No Return'
   END AS return_type
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cd.cd_education_status = 'Advanced Degree'
  AND ca.ca_gmt_offset = -5.00
  AND cr.cr_reason_sk = 58
  AND wr.wr_return_amt > 50.00
  AND ws.web_class = 'Unknown'
  AND ss.ss_customer_sk IN (SELECT customer_sk FROM catalog_not_web)
ORDER BY ss.ss_net_profit DESC, profit_rank_state
LIMIT 100
