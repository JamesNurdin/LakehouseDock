WITH
    sales_data AS (
        SELECT
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            i.i_item_sk,
            i.i_brand,
            i.i_class,
            i.i_color,
            i.i_container,
            cp.cp_type,
            cc.cc_state,
            ca.ca_state AS ca_state,
            p.p_promo_name,
            p.p_discount_active
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE i.i_class = 'shirts'
          AND i.i_color = 'blue'
          AND i.i_container = 'Unknown'
          AND cp.cp_type = 'monthly'
          AND cc.cc_state = 'CA'
          AND p.p_discount_active = 'Y'
          AND cs.cs_quantity > 1
    ),
    returns_data AS (
        SELECT
            sr.sr_item_sk,
            r.r_reason_desc,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss,
            ca2.ca_state AS return_state
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
        WHERE r.r_reason_desc = 'Defective'
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 10
          AND i.i_brand = 'BrandX'
    ),
    inventory_data AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_warehouse_sk IN (13, 6)
          AND inv.inv_quantity_on_hand > 0
          AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
    ),
    intersect_keys AS (
        SELECT i_item_sk FROM sales_data
        INTERSECT
        SELECT sr_item_sk FROM returns_data
    ),
    except_keys AS (
        SELECT i_item_sk FROM sales_data
        EXCEPT
        SELECT sr_item_sk FROM returns_data
    )
SELECT
    i_brand,
    i_class,
    cp_type,
    cc_state,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    SUM(cs_quantity) AS total_quantity_sold,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    MIN(cs_ext_sales_price) AS min_sale,
    MAX(cs_ext_sales_price) AS max_sale
FROM (
    SELECT
        sd.i_item_sk,
        sd.i_brand,
        sd.i_class,
        sd.cp_type,
        sd.cc_state,
        sd.cs_quantity,
        sd.cs_ext_sales_price,
        sd.cs_net_profit
    FROM sales_data sd
    WHERE sd.i_item_sk IN (SELECT i_item_sk FROM intersect_keys)
      AND sd.i_item_sk NOT IN (SELECT i_item_sk FROM except_keys)
      AND EXISTS (SELECT 1 FROM inventory_data inv WHERE inv.inv_item_sk = sd.i_item_sk)
) s
GROUP BY CUBE (i_brand, i_class, cp_type, cc_state)
ORDER BY i_brand, i_class, cp_type, cc_state
LIMIT 100
