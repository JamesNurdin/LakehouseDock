WITH base AS (
   SELECT
      d.d_year,
      cc.cc_name,
      ca.ca_state,
      wp.wp_type,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      ws.ws_quantity,
      ws.ws_net_paid,
      sr.sr_return_amt,
      sr.sr_fee,
      wp.wp_max_ad_count
   FROM date_dim d
   LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2001                              -- predicate 1
     AND cc.cc_state = 'CA'                                          -- predicate 2
     AND ca.ca_country = 'United States'                             -- predicate 3
     AND wp.wp_max_ad_count >= 2                                     -- predicate 4
     AND cs.cs_quantity >= 5                                         -- predicate 5
     AND sr.sr_fee BETWEEN 5 AND 20                                   -- predicate 6
     AND ws.ws_quantity < 10                                         -- predicate 7
     AND EXISTS (                                                     -- subquery predicate
         SELECT 1
         FROM web_sales ws2
         WHERE ws2.ws_order_number = cs.cs_order_number
           AND ws2.ws_quantity > 5
     )
)
SELECT
   d_year,
   cc_name,
   ca_state,
   wp_type,
   SUM(cs_net_paid) AS total_catalog_sales,
   SUM(ws_net_paid) AS total_web_sales,
   SUM(sr_return_amt) AS total_store_returns,
   COUNT(DISTINCT cs_order_number) AS distinct_orders,
   CASE
      WHEN SUM(cs_net_profit) > 0 THEN 'Profitable'
      ELSE 'Loss'
   END AS sales_status
FROM base
GROUP BY d_year, cc_name, ca_state, wp_type
HAVING SUM(cs_net_paid) > 1000
ORDER BY total_catalog_sales DESC
LIMIT 100
