WITH cs_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            SUM(cs.cs_net_paid)          AS total_cs_paid,
            SUM(cs.cs_net_profit)        AS total_cs_profit
        FROM catalog_sales cs
        GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
    ),
    ws_agg AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_date_sk,
            SUM(ws.ws_net_paid)          AS total_ws_paid,
            SUM(ws.ws_net_profit)        AS total_ws_profit
        FROM web_sales ws
        GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
    ),
    intersect_items AS (
        SELECT cs_item_sk AS item_sk, cs_sold_date_sk AS date_sk FROM cs_agg
        INTERSECT
        SELECT ws_item_sk, ws_sold_date_sk FROM ws_agg
    )
SELECT
    i.i_item_id,
    d.d_date,
    SUM(cs_agg.total_cs_paid)            AS total_catalog_paid,
    SUM(ws_agg.total_ws_paid)            AS total_web_paid,
    SUM(cs_agg.total_cs_profit) - SUM(ws_agg.total_ws_profit) AS profit_diff,
    CASE
        WHEN SUM(cs_agg.total_cs_profit) > SUM(ws_agg.total_ws_profit) THEN 'CatalogHigher'
        ELSE 'WebHigher'
    END                                 AS profit_source,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    COUNT(DISTINCT rs.r_reason_id)       AS num_return_reasons
FROM intersect_items ii
JOIN cs_agg cs_agg
    ON cs_agg.cs_item_sk = ii.item_sk AND cs_agg.cs_sold_date_sk = ii.date_sk
JOIN ws_agg ws_agg
    ON ws_agg.ws_item_sk = ii.item_sk AND ws_agg.ws_sold_date_sk = ii.date_sk
-- bring back full catalog_sales row to reach other dimensions
JOIN catalog_sales cs_full
    ON cs_full.cs_item_sk = ii.item_sk AND cs_full.cs_sold_date_sk = ii.date_sk
JOIN web_sales ws_full
    ON ws_full.ws_item_sk = ii.item_sk AND ws_full.ws_sold_date_sk = ii.date_sk
JOIN item i
    ON i.i_item_sk = ii.item_sk
JOIN date_dim d
    ON d.d_date_sk = ii.date_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs_full.cs_call_center_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs_full.cs_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs_full.cs_warehouse_sk
JOIN promotion p
    ON p.p_promo_sk = cs_full.cs_promo_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs_full.cs_order_number
JOIN reason rs
    ON rs.r_reason_sk = cr.cr_reason_sk
JOIN web_site webs
    ON webs.web_site_sk = ws_full.ws_web_site_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws_full.ws_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws_full.ws_order_number
JOIN customer c
    ON c.c_customer_sk = cs_full.cs_bill_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs_full.cs_bill_cdemo_sk
WHERE i.i_manufact = 'barcallyable                                      '
  AND d.d_year = 1999
  AND cc.cc_state = 'CA'
  AND webs.web_state = 'CA'
GROUP BY i.i_item_id, d.d_date
ORDER BY total_catalog_paid DESC
LIMIT 100
