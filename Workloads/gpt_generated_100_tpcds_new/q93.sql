WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    store_item_set AS (
        SELECT DISTINCT ss_item_sk AS item_sk
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450830 AND 2450835
    ),
    web_item_set AS (
        SELECT DISTINCT ws_item_sk AS item_sk
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2450830 AND 2450835
    ),
    exclusive_items AS (
        SELECT item_sk FROM store_item_set
        EXCEPT
        SELECT item_sk FROM web_item_set
    )
SELECT
    i.i_item_id,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    ca.ca_city,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    t_ss.t_minute,
    p.p_promo_name,
    cr.cr_return_amount,
    ss.ss_ext_sales_price,
    ws.ws_ext_sales_price,
    (COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) - COALESCE(cr.cr_return_amount, 0)) AS net_sales,
    ROW_NUMBER() OVER (
        PARTITION BY i.i_item_id
        ORDER BY (COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) - COALESCE(cr.cr_return_amount, 0)) DESC
    ) AS sales_rank,
    CASE WHEN hd.hd_income_band_sk > 5 THEN 'High' ELSE 'Low' END AS income_group,
    channel_detail
FROM exclusive_items ei
JOIN item i ON ei.item_sk = i.i_item_sk
JOIN inv_agg ia ON i.i_item_sk = ia.inv_item_sk
JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t_ss.t_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_time_sk = t_ss.t_time_sk
LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
WHERE
    t_ss.t_minute BETWEEN 10 AND 20
    AND i.i_category = 'Sports'
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cr.cr_return_amount > 100
ORDER BY net_sales DESC
LIMIT 100
