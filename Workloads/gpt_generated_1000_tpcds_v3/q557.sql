/*
  Goal: Analyze combined catalog and web sales performance per item and warehouse, categorizing items by profit level and promotion type while applying several business filters.
*/
WITH agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        w.w_warehouse_name AS warehouse_name,
        ib.ib_upper_bound,
        p.p_discount_active,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(cs.cs_quantity) AS catalog_qty,
        SUM(ws.ws_quantity) AS web_qty,
        CASE
            WHEN SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) > 5000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM catalog_sales cs
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE i.i_brand = 'BrandX'
      AND p.p_channel_tv = 'N'
      AND ib.ib_upper_bound > 60000
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND ca.ca_country = 'United States'
    GROUP BY i.i_item_id, i.i_product_name, w.w_warehouse_name, ib.ib_upper_bound, p.p_discount_active
)
SELECT
    item_id,
    product_name,
    warehouse_name,
    profit_category,
    (catalog_net_paid + web_net_paid) AS total_net_paid,
    (catalog_qty + web_qty) AS total_quantity,
    CASE WHEN profit_category = 'High' THEN 'Priority' ELSE 'Standard' END AS priority_level
FROM agg
WHERE profit_category = 'High'
UNION ALL
SELECT
    item_id,
    product_name,
    warehouse_name,
    profit_category,
    (catalog_net_paid + web_net_paid) AS total_net_paid,
    (catalog_qty + web_qty) AS total_quantity,
    CASE WHEN profit_category = 'High' THEN 'Priority' ELSE 'Standard' END AS priority_level
FROM agg
WHERE profit_category = 'Low'
ORDER BY total_net_paid DESC
LIMIT 100
