WITH inventory_agg AS (
    SELECT
        inv.inv_item_sk AS i_item_sk,
        inv.inv_warehouse_sk AS w_warehouse_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    i_sales.i_category AS item_category,
    d_sold.d_year AS sales_year,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(
        COALESCE(cr.cr_net_loss, 0) +
        COALESCE(sr.sr_net_loss, 0) +
        COALESCE(wr.wr_net_loss, 0)
    ) AS total_return_loss,
    AVG(ia.avg_qty_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i_sales
    ON cs.cs_item_sk = i_sales.i_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i_sales.i_item_sk
    AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
LEFT JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i_sales.i_item_sk
    AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
LEFT JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN customer_demographics cd_wr_ref
    ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
LEFT JOIN household_demographics hd_wr_ref
    ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
LEFT JOIN inventory_agg ia
    ON ia.i_item_sk = i_sales.i_item_sk
    AND ia.w_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
    WHERE p2.p_item_sk = i_sales.i_item_sk
      AND d2.d_year = 2001
)
GROUP BY i_sales.i_category, d_sold.d_year
ORDER BY total_net_profit DESC
LIMIT 100
