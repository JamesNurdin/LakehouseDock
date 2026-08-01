-- Goal: Analyze net sales and profit by year, item category and sales channel, keeping all years (right join),
-- while filtering on specific category, county and carrier, using sampled data, set operations, subqueries, and rollup subtotals.
WITH ss_sample AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
ws_sample AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
),
sales_union AS (
   SELECT
       ss_sold_date_sk AS date_sk,
       ss_item_sk      AS item_sk,
       ss_customer_sk  AS cust_sk,
       ss_addr_sk      AS addr_sk,
       ss_net_paid     AS net_paid,
       ss_net_profit   AS net_profit,
       CAST(NULL AS integer) AS ship_mode_sk,
       CAST(NULL AS integer) AS web_site_sk,
       'store'          AS sales_channel
   FROM ss_sample
   UNION
   SELECT
       ws_sold_date_sk,
       ws_item_sk,
       ws_bill_customer_sk,
       ws_bill_addr_sk,
       ws_net_paid,
       ws_net_profit,
       ws_ship_mode_sk,
       ws_web_site_sk,
       'web'          AS sales_channel
   FROM ws_sample
),
items_sold AS (
   SELECT date_sk, item_sk, cust_sk, addr_sk, net_paid, net_profit, ship_mode_sk, web_site_sk, sales_channel
   FROM sales_union
   EXCEPT
   SELECT
       sr_returned_date_sk,
       sr_item_sk,
       sr_customer_sk,
       sr_addr_sk,
       0,
       0,
       CAST(NULL AS integer),
       CAST(NULL AS integer),
       'store'
   FROM store_returns
),
high_value_customers AS (
   SELECT cust_sk
   FROM (
       SELECT ss_customer_sk AS cust_sk, SUM(ss_net_paid) AS total_paid
       FROM store_sales
       GROUP BY ss_customer_sk
   ) t
   WHERE total_paid > 100000
)
SELECT
   d.d_year,
   i.i_category,
   s.sales_channel,
   COUNT(DISTINCT s.cust_sk)                                     AS unique_customers,
   SUM(s.net_paid)                                               AS total_net_paid,
   AVG(s.net_profit)                                             AS avg_net_profit,
   SUM(CASE WHEN s.sales_channel = 'web' THEN s.net_paid ELSE 0 END) AS web_net_paid,
   COALESCE(sm.sm_carrier, 'UNKNOWN')                            AS ship_carrier,
   COALESCE(ws.web_name, 'NO_SITE')                              AS web_site_name,
   (SELECT AVG(ss_net_profit) FROM store_sales)                AS overall_avg_profit
FROM items_sold s
RIGHT OUTER JOIN date_dim d
   ON s.date_sk = d.d_date_sk
   AND d.d_year = 2001
LEFT  OUTER JOIN item i
   ON s.item_sk = i.i_item_sk
LEFT  OUTER JOIN customer c
   ON s.cust_sk = c.c_customer_sk
LEFT  OUTER JOIN customer_address ca
   ON s.addr_sk = ca.ca_address_sk
LEFT  OUTER JOIN ship_mode sm
   ON s.ship_mode_sk = sm.sm_ship_mode_sk
LEFT  OUTER JOIN web_site ws
   ON s.web_site_sk = ws.web_site_sk
WHERE i.i_category = 'Sports'
  AND ca.ca_county = 'York County'
  AND sm.sm_carrier = 'MSC'
  AND s.cust_sk IN (SELECT cust_sk FROM high_value_customers)
GROUP BY ROLLUP (d.d_year, i.i_category, s.sales_channel, sm.sm_carrier, ws.web_name)
ORDER BY d.d_year DESC, i.i_category, s.sales_channel
LIMIT 100
