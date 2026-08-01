WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        r.r_reason_desc,
        sm.sm_type,
        sm.sm_contract,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        we.web_country,
        we.web_name
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cr.cr_returning_cdemo_sk IN (1914871, 498439)
      AND cr.cr_return_ship_cost > 1000
      AND cp.cp_catalog_page_sk = 544
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND sm.sm_contract = 'P7FBIt8yd'
      AND inv.inv_quantity_on_hand > 500
      AND we.web_country = 'United States'
      AND NOT EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = cr.cr_item_sk
            AND inv2.inv_quantity_on_hand = 0
      )
)
SELECT
    jd.w_warehouse_name,
    jd.sm_type,
    jd.r_reason_desc,
    CASE WHEN jd.cr_return_amount > 500 THEN 'High' ELSE 'Low' END AS return_amount_category,
    SUM(jd.cr_return_amount) AS total_return_amount,
    AVG(jd.ws_sales_price) AS avg_ws_sales_price,
    COUNT(*) AS transaction_cnt,
    MIN(jd.cr_return_ship_cost) AS min_return_ship_cost,
    MAX(jd.cr_return_quantity) AS max_return_quantity,
    (
        SELECT SUM(ws2.ws_quantity)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = jd.w_warehouse_sk
    ) AS total_ws_quantity_per_warehouse,
    ROW_NUMBER() OVER (ORDER BY jd.cr_returned_date_sk DESC) AS rn
FROM joined_data jd
GROUP BY
    jd.w_warehouse_name,
    jd.sm_type,
    jd.r_reason_desc,
    CASE WHEN jd.cr_return_amount > 500 THEN 'High' ELSE 'Low' END,
    jd.w_warehouse_sk,
    jd.cr_returned_date_sk
ORDER BY rn
LIMIT 100
