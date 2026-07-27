WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    d_sales.d_year,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Normal' END AS sales_category,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
    (
        SELECT AVG(p_sub.p_cost)
        FROM promotion p_sub
        WHERE p_sub.p_item_sk = i.i_item_sk
    ) AS avg_promo_cost,
    inv.total_qty_on_hand
FROM web_sales ws
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_sales.d_year = 2001
  AND i.i_current_price BETWEEN 10 AND 100
  AND w.w_county = 'Fairfield County'
  AND r.r_reason_desc IS NOT NULL
  AND ws.ws_quantity > 5
ORDER BY ws.ws_ext_sales_price DESC
LIMIT 100
