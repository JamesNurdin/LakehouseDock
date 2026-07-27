WITH catalog_agg AS (
   SELECT
      'Catalog' AS src,
      cc.cc_name AS entity_name,
      SUM(cr.cr_return_amount) AS total_return,
      ROW_NUMBER() OVER (PARTITION BY cc.cc_division ORDER BY SUM(cr.cr_return_amount) DESC) AS rank
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   WHERE cc.cc_division IN (1, 2, 3)
     AND cr.cr_return_amount > 100
   GROUP BY cc.cc_name, cc.cc_division
),
web_agg AS (
   SELECT
      'Web' AS src,
      ws.web_name AS entity_name,
      SUM(wr.wr_return_amt) AS total_return,
      ROW_NUMBER() OVER (PARTITION BY ws.web_state ORDER BY SUM(wr.wr_return_amt) DESC) AS rank
   FROM web_returns wr
   JOIN web_sales wsale ON wr.wr_order_number = wsale.ws_order_number
   JOIN web_site ws ON wsale.ws_web_site_sk = ws.web_site_sk
   JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
   WHERE ws.web_state = 'CA'
     AND wr.wr_return_amt > 50
   GROUP BY ws.web_name, ws.web_state
)
SELECT src, entity_name, total_return, rank
FROM catalog_agg
UNION ALL
SELECT src, entity_name, total_return, rank
FROM web_agg
ORDER BY total_return DESC
LIMIT 100
