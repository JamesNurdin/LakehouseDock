WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (5, 12, 15)
    GROUP BY inv_item_sk
),
item_filtered AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_category,
           i.i_product_name
    FROM item i
    WHERE i.i_brand = 'Brand#12'
      AND i.i_category = 'Sports'
)
SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    ia.total_qty_on_hand,
    (SELECT MAX(total_qty_on_hand) FROM inv_agg) AS max_qty_on_hand
FROM item_filtered i
JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN customer_address ca_refund ON ca_refund.ca_address_sk = cr.cr_refunded_addr_sk
JOIN customer_address ca_return ON ca_return.ca_address_sk = cr.cr_returning_addr_sk
JOIN customer_address ca_store ON ca_store.ca_address_sk = sr.sr_addr_sk
JOIN customer_address ca_web_refund ON ca_web_refund.ca_address_sk = wr.wr_refunded_addr_sk
JOIN customer_address ca_web_return ON ca_web_return.ca_address_sk = wr.wr_returning_addr_sk
WHERE cr.cr_return_quantity > 25
  AND sr.sr_return_quantity > 10
  AND wr.wr_return_quantity > 15
  AND ca_refund.ca_zip = '68252'
  AND ca_store.ca_state = 'CA'
GROUP BY
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    ia.total_qty_on_hand
HAVING SUM(cr.cr_return_amount) > 100
ORDER BY catalog_return_amount DESC
LIMIT 100
