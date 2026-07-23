SELECT
    d.d_year AS year,
    i.i_category AS category,
    ca_bill.ca_state AS state,
    p.p_promo_name AS promo_name,
    sm.sm_type AS ship_type,
    w.web_name AS website_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    (SELECT AVG(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS overall_avg_discount
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
    AND sr.sr_addr_sk = ca_bill.ca_address_sk
    AND sr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 1998
  AND i.i_category = 'Books'
  AND ca_bill.ca_state = 'TX'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
GROUP BY d.d_year, i.i_category, ca_bill.ca_state, p.p_promo_name, sm.sm_type, w.web_name
ORDER BY total_net_paid DESC
LIMIT 100
