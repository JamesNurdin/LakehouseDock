WITH item_inventory AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_category,
           i.i_current_price,
           inv.inv_quantity_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_brand = 'Brand#12'
)
SELECT
    cp.cp_department,
    i.i_brand,
    sm.sm_type,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    MAX(ii.inv_quantity_on_hand) AS max_inventory_qty,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_overall
FROM catalog_page cp
JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN item_inventory ii ON ii.i_item_sk = i.i_item_sk
WHERE ca.ca_country = 'United States'
  AND sm.sm_type = 'AIR'
  AND p.p_discount_active = 'Y'
GROUP BY
    cp.cp_department,
    i.i_brand,
    sm.sm_type
