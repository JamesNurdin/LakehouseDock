WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_promo_sk,
        i.i_item_sk,
        i.i_current_price,
        i.i_brand,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        w.w_gmt_offset,
        cp.cp_department,
        cp.cp_type,
        cd.cd_gender,
        cd.cd_education_status,
        p.p_promo_sk,
        p.p_discount_active,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    sd.w_warehouse_name,
    sd.cp_department,
    sd.cd_gender,
    CASE WHEN sd.w_gmt_offset >= 0 THEN 'East' ELSE 'West' END AS region,
    SUM(sd.cs_ext_sales_price) AS total_sales,
    SUM(sd.cs_net_profit) AS total_profit,
    AVG(sd.cs_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN sd.p_discount_active = 'Y' THEN sd.cs_ext_sales_price ELSE 0 END) AS promo_sales,
    COUNT(DISTINCT sd.cs_order_number) AS order_count,
    SUM(sd.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount
FROM sales_data sd
JOIN catalog_returns cr ON cr.cr_order_number = sd.cs_order_number AND cr.cr_item_sk = sd.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = sd.i_item_sk
WHERE sd.i_current_price > 50
  AND sd.w_state = 'CA'
  AND sd.inv_quantity_on_hand > 500
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = sd.i_item_sk
          AND sr2.sr_return_quantity > 0
          AND sr2.sr_returned_date_sk > sd.cs_sold_date_sk
    )
GROUP BY sd.w_warehouse_name, sd.cp_department, sd.cd_gender, sd.w_gmt_offset
ORDER BY total_sales DESC
LIMIT 100
