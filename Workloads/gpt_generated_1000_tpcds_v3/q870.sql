WITH cat_data AS (
    SELECT
        i.i_category AS category,
        cc.cc_name AS call_center_name,
        NULL AS web_page_type,
        r.r_reason_desc AS reason_desc,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk AND ca.ca_address_sk = sr.sr_addr_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND cs.cs_quantity > 5
      AND cs.cs_sales_price > 100
    GROUP BY i.i_category, cc.cc_name, r.r_reason_desc
),
web_data AS (
    SELECT
        i.i_category AS category,
        NULL AS call_center_name,
        wp.wp_type AS web_page_type,
        r.r_reason_desc AS reason_desc,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        'web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk AND ca.ca_address_sk = sr.sr_addr_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND wp.wp_max_ad_count = 2
      AND r.r_reason_desc = 'Package was damaged'
    GROUP BY i.i_category, wp.wp_type, r.r_reason_desc
)
SELECT *
FROM cat_data
UNION ALL
SELECT *
FROM web_data
ORDER BY total_sales DESC
LIMIT 100
