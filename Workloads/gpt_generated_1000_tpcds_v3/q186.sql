WITH inv_cte AS (
    SELECT inv_warehouse_sk,
           inv_item_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (1, 3)
)
SELECT
    s.s_store_id,
    s.s_city,
    p.p_promo_id,
    w.w_warehouse_id,
    SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price)               AS total_store_sales,
    SUM(cr.cr_return_amount)                 AS total_catalog_returns,
    SUM(wr.wr_return_amt)                    AS total_web_returns,
    SUM(i.inv_quantity_on_hand)              AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number)       AS distinct_orders
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inv_cte i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_returns wr
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND cs.cs_coupon_amt > 1000.00
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND wr.wr_return_quantity > 2
GROUP BY s.s_store_id,
         s.s_city,
         p.p_promo_id,
         w.w_warehouse_id
ORDER BY total_catalog_sales DESC
LIMIT 100
