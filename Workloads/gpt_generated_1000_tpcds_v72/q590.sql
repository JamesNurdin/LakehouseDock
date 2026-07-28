SELECT
    cc.cc_name,
    i.i_product_name,
    w.w_warehouse_name,
    ca.ca_state,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    AVG(wr.wr_return_amt_inc_tax) AS avg_web_return_inc_tax,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    promo_stats.max_promo_cost
FROM tpcds.call_center cc
JOIN tpcds.catalog_sales cs
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN tpcds.customer_address ca
  ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN tpcds.item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN tpcds.promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN tpcds.warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN tpcds.inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_customer_sk = c.c_customer_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_order_number = cs.cs_order_number
JOIN tpcds.web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_order_number = ws.ws_order_number
CROSS JOIN LATERAL (
    SELECT MAX(p2.p_cost) AS max_promo_cost
    FROM tpcds.promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
) AS promo_stats
WHERE cc.cc_country = 'United States'
  AND cs.cs_sold_date_sk = 2451088
  AND inv.inv_warehouse_sk = 5
  AND wr.wr_return_amt_inc_tax > 100
  AND EXISTS (
        SELECT 1
        FROM tpcds.promotion p3
        WHERE p3.p_item_sk = i.i_item_sk
          AND p3.p_discount_active = 'Y'
    )
GROUP BY
    cc.cc_name,
    i.i_product_name,
    w.w_warehouse_name,
    ca.ca_state,
    promo_stats.max_promo_cost
ORDER BY total_sales DESC
LIMIT 100
