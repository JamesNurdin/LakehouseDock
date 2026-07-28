WITH cs_detail AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_qty
    FROM catalog_sales cs
    GROUP BY
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number
),
ws_detail AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    td_sold.t_time AS sold_time,
    td_sold.t_shift,
    cs_detail.catalog_profit,
    ws_detail.web_profit,
    (cs_detail.catalog_profit + ws_detail.web_profit) AS total_profit,
    CASE
        WHEN (cs_detail.catalog_profit + ws_detail.web_profit) > 20000 THEN 'High'
        WHEN (cs_detail.catalog_profit + ws_detail.web_profit) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (cs_detail.catalog_profit + ws_detail.web_profit) DESC) AS category_rank,
    cc.cc_name,
    w_cc.w_warehouse_name AS catalog_warehouse,
    w_ws.w_warehouse_name AS web_warehouse,
    cp_sales.cp_description AS catalog_page_desc,
    cp_dup.cp_type AS catalog_page_type_dup,
    wp.wp_url,
    ws_site.web_name,
    EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_order_number = cs_detail.cs_order_number
          AND r.r_reason_desc = 'Damaged'
    ) AS has_damaged_return
FROM cs_detail
JOIN ws_detail
    ON cs_detail.cs_item_sk = ws_detail.ws_item_sk
   AND cs_detail.cs_sold_date_sk = ws_detail.ws_sold_date_sk
JOIN item i
    ON i.i_item_sk = cs_detail.cs_item_sk
JOIN time_dim td_sold
    ON td_sold.t_time_sk = cs_detail.cs_sold_time_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs_detail.cs_call_center_sk
JOIN warehouse w_cc
    ON w_cc.w_warehouse_sk = cs_detail.cs_warehouse_sk
JOIN catalog_page cp_sales
    ON cp_sales.cp_catalog_page_sk = cs_detail.cs_catalog_page_sk
-- reuse catalog_page with a different alias for a second role
JOIN catalog_page cp_dup
    ON cp_dup.cp_catalog_page_sk = cs_detail.cs_catalog_page_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws_detail.ws_web_page_sk
JOIN web_site ws_site
    ON ws_site.web_site_sk = ws_detail.ws_web_site_sk
JOIN warehouse w_ws
    ON w_ws.w_warehouse_sk = ws_detail.ws_warehouse_sk
WHERE i.i_category = 'Electronics'
  AND td_sold.t_shift = 'first'
ORDER BY total_profit DESC
LIMIT 100
