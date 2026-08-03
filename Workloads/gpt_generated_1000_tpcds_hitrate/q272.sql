WITH excluded_addresses AS (
   SELECT ca.ca_address_sk
   FROM store_returns sr
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE sr.sr_return_ship_cost > 50
)
SELECT customer_sk, state
FROM (
   SELECT cr.cr_returning_customer_sk AS customer_sk,
          ca.ca_state AS state
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
   WHERE cr.cr_return_amount > 100
     AND NOT EXISTS (
         SELECT 1 FROM excluded_addresses ea WHERE ea.ca_address_sk = ca.ca_address_sk
     )

   UNION ALL

   SELECT wr.wr_returning_customer_sk AS customer_sk,
          ca.ca_state AS state
   FROM web_returns wr
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
   WHERE wr.wr_return_amt > 100
     AND NOT EXISTS (
         SELECT 1 FROM excluded_addresses ea WHERE ea.ca_address_sk = ca.ca_address_sk
     )
) AS combined
EXCEPT
SELECT sr.sr_customer_sk AS customer_sk,
       ca.ca_state AS state
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_amt > 200
ORDER BY customer_sk
LIMIT 100
