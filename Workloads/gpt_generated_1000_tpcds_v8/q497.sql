WITH sampled_item AS (
    SELECT *
    FROM item i
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        w.w_warehouse_name,
        cc.cc_name                AS call_center_name,
        p.p_promo_name,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        cs.cs_quantity,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        ws.ws_quantity            AS ws_quantity,
        ws.ws_net_profit          AS ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        r_cr.r_reason_desc        AS catalog_return_reason,
        r_wr.r_reason_desc        AS web_return_reason,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM sampled_item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    LEFT JOIN income_band ib_ws ON hd_ws_bill.hd_income_band_sk = ib_ws.ib_income_band_sk
    CROSS JOIN (SELECT 1 AS dummy) c
),
full_reason AS (
    SELECT r1.r_reason_sk,
           r1.r_reason_desc AS reason_desc1,
           r2.r_reason_desc AS reason_desc2
    FROM reason r1
    FULL OUTER JOIN reason r2 ON r1.r_reason_sk = r2.r_reason_sk
)
SELECT
    jd.i_item_id,
    jd.i_category,
    jd.w_warehouse_name,
    jd.call_center_name,
    jd.p_promo_name,
    jd.profit_category,
    SUM(jd.cs_quantity)            AS total_quantity_sold,
    SUM(jd.cs_net_profit)          AS total_net_profit,
    SUM(jd.cr_return_quantity)    AS total_return_qty,
    SUM(jd.cr_net_loss)            AS total_return_loss,
    COUNT(DISTINCT jd.profit_rank) AS distinct_profit_ranks,
    MAX(jd.profit_rank)            AS max_profit_rank,
    fr.reason_desc1,
    fr.reason_desc2
FROM joined_data jd
LEFT JOIN full_reason fr ON fr.r_reason_sk = (
    SELECT r_reason_sk FROM reason LIMIT 1
)
WHERE jd.ib_lower_bound IS NOT NULL
  AND jd.profit_category = 'High'
GROUP BY
    jd.i_item_id,
    jd.i_category,
    jd.w_warehouse_name,
    jd.call_center_name,
    jd.p_promo_name,
    jd.profit_category,
    fr.reason_desc1,
    fr.reason_desc2
ORDER BY total_net_profit DESC
LIMIT 100
