WITH
    sales_agg AS (
        SELECT
            sm.sm_ship_mode_id,
            sm.sm_type,
            SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
            SUM(cs.cs_ext_sales_price) AS catalog_sales_ext_sales
        FROM catalog_sales cs
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        GROUP BY sm.sm_ship_mode_id, sm.sm_type
    ),
    web_sales_agg AS (
        SELECT
            sm.sm_ship_mode_id,
            sm.sm_type,
            SUM(ws.ws_net_profit) AS web_sales_net_profit,
            SUM(ws.ws_ext_sales_price) AS web_sales_ext_sales
        FROM web_sales ws
        JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        GROUP BY sm.sm_ship_mode_id, sm.sm_type
    ),
    combined_sales AS (
        SELECT
            s.sm_ship_mode_id,
            s.sm_type,
            s.catalog_sales_net_profit + w.web_sales_net_profit AS total_sales_net_profit,
            s.catalog_sales_ext_sales + w.web_sales_ext_sales AS total_sales_ext_sales
        FROM sales_agg s
        JOIN web_sales_agg w
            ON s.sm_ship_mode_id = w.sm_ship_mode_id
           AND s.sm_type = w.sm_type
    ),
    returns_agg AS (
        SELECT
            sm.sm_ship_mode_id,
            sm.sm_type,
            r.r_reason_desc,
            SUM(cr.cr_net_loss) AS total_return_loss,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN catalog_sales cs
            ON cr.cr_item_sk = cs.cs_item_sk
           AND cr.cr_order_number = cs.cs_order_number
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        GROUP BY sm.sm_ship_mode_id, sm.sm_type, r.r_reason_desc
    )
SELECT
    cs.sm_ship_mode_id,
    cs.sm_type,
    ra.r_reason_desc,
    cs.total_sales_net_profit,
    cs.total_sales_ext_sales,
    ra.total_return_loss,
    ra.total_return_amount
FROM combined_sales cs
JOIN returns_agg ra
    ON cs.sm_ship_mode_id = ra.sm_ship_mode_id
   AND cs.sm_type = ra.sm_type
ORDER BY cs.sm_ship_mode_id, ra.r_reason_desc
