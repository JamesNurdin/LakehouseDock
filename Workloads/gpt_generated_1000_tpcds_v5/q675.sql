WITH sales AS (
   SELECT i.i_item_id AS item_id,
          i.i_product_name AS product_name,
          ca.ca_state AS state,
          'sales' AS metric,
          SUM(ss.ss_ext_sales_price) AS amount,
          SUM(ss.ss_quantity) AS units
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
     AND p.p_channel_tv = 'N'
   GROUP BY i.i_item_id, i.i_product_name, ca.ca_state
),
returns AS (
   SELECT i.i_item_id AS item_id,
          i.i_product_name AS product_name,
          ca.ca_state AS state,
          'return' AS metric,
          SUM(cr.cr_return_amount) AS amount,
          SUM(cr.cr_return_quantity) AS units
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450825
   GROUP BY i.i_item_id, i.i_product_name, ca.ca_state
)
SELECT item_id,
       product_name,
       state,
       metric,
       amount,
       units
FROM sales
UNION ALL
SELECT item_id,
       product_name,
       state,
       metric,
       amount,
       units
FROM returns
ORDER BY amount DESC
LIMIT 100
