WITH RECURSIVE sel_dates (d_date_sk, d_date, d_year) AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date = DATE '1900-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    JOIN sel_dates sd ON d.d_date_sk = sd.d_date_sk + 1
    WHERE sd.d_date_sk < 10
)
SELECT
    w.w_warehouse_name,
    r.r_reason_desc,
    cd_refunded.cd_gender,
    SUM(cr.cr_net_loss) AS total_cr_net_loss,
    SUM(wr.wr_net_loss) AS total_wr_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM sel_dates d_ret
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_order_number = cr.cr_order_number
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN web_sales ws
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
JOIN warehouse w2
    ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_wr.d_date_sk
   AND inv.inv_warehouse_sk = w2.w_warehouse_sk
WHERE cr.cr_net_loss > (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
    )
  AND ib.ib_lower_bound >= 30000
  AND d_ret.d_year = 1900
GROUP BY w.w_warehouse_name, r.r_reason_desc, cd_refunded.cd_gender
HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 1000
ORDER BY total_cr_net_loss DESC
LIMIT 100
