WITH
  store_sales_agg AS (
    SELECT ss_item_sk,
           ss_store_sk,
           SUM(ss_ext_sales_price) AS store_sales_total,
           SUM(ss_net_profit) AS store_profit
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_item_sk, ss_store_sk
  ),
  web_sales_agg AS (
    SELECT ws_item_sk,
           ws_web_site_sk,
           SUM(ws_ext_sales_price) AS web_sales_total,
           SUM(ws_net_profit) AS web_profit
    FROM web_sales
    WHERE ws_quantity > 1
    GROUP BY ws_item_sk, ws_web_site_sk
  ),
  sampled_address AS (
    SELECT *
    FROM customer_address TABLESAMPLE BERNOULLI (10)
  ),
  store_return_reason AS (
    SELECT sr.sr_ticket_number AS order_num,
           r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  ),
  web_return_reason AS (
    SELECT wr.wr_order_number AS order_num,
           r.r_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  ),
  store_order_numbers AS (
    SELECT ss_ticket_number AS order_num FROM store_sales
  ),
  web_order_numbers AS (
    SELECT ws_order_number AS order_num FROM web_sales
  ),
  common_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk FROM catalog_returns cr
    INTERSECT
    SELECT wr.wr_refunded_customer_sk FROM web_returns wr
  ),
  store_not_web_orders AS (
    SELECT order_num FROM store_order_numbers
    EXCEPT
    SELECT order_num FROM web_order_numbers
  )
SELECT
  cr.cr_order_number,
  cr.cr_return_amount,
  ca.ca_state,
  cd.cd_credit_rating,
  r.r_reason_desc,
  ss_agg.store_sales_total,
  ws_agg.web_sales_total,
  ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cr.cr_net_loss DESC) AS rn_state,
  RANK() OVER (ORDER BY cr.cr_net_loss DESC) AS overall_rank,
  CASE WHEN cr.cr_return_amount > 5000 THEN 'High' ELSE 'Normal' END AS return_category,
  (SELECT COUNT(*) FROM sampled_address) AS sampled_address_cnt
FROM catalog_returns cr
JOIN sampled_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_sales_agg ss_agg ON cr.cr_item_sk = ss_agg.ss_item_sk
LEFT JOIN web_sales_agg ws_agg ON cr.cr_item_sk = ws_agg.ws_item_sk
LEFT JOIN store_return_reason srr ON cr.cr_order_number = srr.order_num
LEFT JOIN web_return_reason wrr ON cr.cr_order_number = wrr.order_num
WHERE cd.cd_credit_rating = 'Good'
  AND ca.ca_state = 'CA'
  AND cr.cr_return_amount > 1000
  AND cr.cr_return_quantity >= 1
  AND r.r_reason_desc LIKE '%damaged%'
  AND cr.cr_returned_date_sk > 2451545
  AND EXISTS (SELECT 1 FROM common_customers cc WHERE cc.cust_sk = cr.cr_refunded_customer_sk)
  AND cr.cr_order_number IN (SELECT order_num FROM store_not_web_orders)
ORDER BY cr.cr_net_loss DESC
LIMIT 100
