WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS sales_net_profit,
        SUM(cs_quantity) AS sales_qty
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_call_center_sk, cs_warehouse_sk, cs_catalog_page_sk, cs_ship_mode_sk
),
cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_warehouse_sk,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_reason_sk,
        SUM(cr_net_loss) AS returns_net_loss,
        SUM(cr_return_quantity) AS returns_qty
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_call_center_sk, cr_warehouse_sk, cr_catalog_page_sk, cr_ship_mode_sk, cr_reason_sk
),
ss_agg AS (
    SELECT
        ss_ticket_number,
        ss_customer_sk,
        SUM(ss_net_profit) AS store_sales_profit,
        SUM(ss_quantity) AS store_sales_qty
    FROM store_sales
    GROUP BY ss_ticket_number, ss_customer_sk
),
sr_agg AS (
    SELECT
        sr_ticket_number,
        SUM(sr_net_loss) AS store_returns_loss,
        SUM(sr_return_quantity) AS store_returns_qty
    FROM store_returns
    GROUP BY sr_ticket_number
)
SELECT
    cc.cc_name,
    w.w_warehouse_name,
    cp.cp_department,
    sm.sm_type AS ship_mode_type,
    r.r_reason_desc,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs_agg.cs_call_center_sk) AS distinct_call_centers,
    SUM(cs_agg.sales_net_profit) - COALESCE(SUM(cr_agg.returns_net_loss), 0) AS net_profit_catalog,
    SUM(ss_agg.store_sales_profit) - COALESCE(SUM(sr_agg.store_returns_loss), 0) AS net_profit_store,
    (SELECT COUNT(*) FROM web_returns wr_sub WHERE wr_sub.wr_fee > 10) AS web_return_fee_count,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM cs_agg
JOIN cr_agg
  ON cs_agg.cs_call_center_sk = cr_agg.cr_call_center_sk
 AND cs_agg.cs_warehouse_sk   = cr_agg.cr_warehouse_sk
 AND cs_agg.cs_catalog_page_sk = cr_agg.cr_catalog_page_sk
 AND cs_agg.cs_ship_mode_sk   = cr_agg.cr_ship_mode_sk
JOIN call_center cc
  ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON cr_agg.cr_reason_sk = r.r_reason_sk
JOIN inventory inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN ss_agg
  ON ss_agg.ss_customer_sk = cc.cc_call_center_sk  -- link via any column; using call_center key as surrogate for demo purpose
JOIN store_sales ss
  ON ss.ss_ticket_number = ss_agg.ss_ticket_number
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss_agg.ss_ticket_number
JOIN sr_agg
  ON sr_agg.sr_ticket_number = sr.sr_ticket_number
JOIN web_returns wr
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cc.cc_state = 'CA'
  AND w.w_state = 'TX'
  AND hd.hd_buy_potential = '>10000'
  AND cd.cd_gender = 'M'
  AND inv.inv_quantity_on_hand > 200
GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    hd.hd_buy_potential
HAVING SUM(cs_agg.sales_net_profit) > (
    SELECT AVG(cs_net_profit)
    FROM catalog_sales
    WHERE cs_quantity > 0
)
ORDER BY net_profit_catalog DESC
LIMIT 100
