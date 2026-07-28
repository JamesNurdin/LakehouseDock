WITH sales AS (
   SELECT
     ws.ws_item_sk AS item_sk,
     SUM(ws.ws_ext_sales_price) AS total_sales
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_credit_rating = 'Good'
     AND d.d_year BETWEEN 2000 AND 2002
   GROUP BY ws.ws_item_sk
),
returns AS (
   SELECT
     sr.sr_item_sk AS item_sk,
     -SUM(sr.sr_return_amt) AS total_sales
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%defect%'
     AND d.d_year BETWEEN 2000 AND 2002
   GROUP BY sr.sr_item_sk
)
SELECT DISTINCT
   c.item_sk,
   c.net_sales,
   (
     SELECT AVG(ws2.ws_ext_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = c.item_sk
   ) AS avg_sale_price
FROM (
   SELECT s.item_sk, s.total_sales AS net_sales FROM sales s
   UNION ALL
   SELECT r.item_sk, r.total_sales AS net_sales FROM returns r
) AS c
WHERE c.item_sk IN (
   SELECT inv.inv_item_sk
   FROM inventory inv
   WHERE inv.inv_quantity_on_hand > 0
)
ORDER BY c.net_sales DESC
LIMIT 100
