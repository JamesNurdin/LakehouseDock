WITH per_store_category AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d.d_year AS year,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(cr.cr_return_amount) AS catalog_return_amt,
        SUM(wr.wr_return_amt) AS web_return_amt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                         AND wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_gmt_offset = -7.00
      AND i.i_category = 'Sports'
      AND ib.ib_upper_bound >= 120000
      AND wr.wr_return_amt_inc_tax > 500
      AND cr.cr_return_amount > 100
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, i.i_category
)
SELECT
    store_id,
    store_name,
    year,
    SUM(catalog_net_loss + web_net_loss) AS total_net_loss,
    SUM(total_qty_on_hand) AS total_qty_on_hand,
    COUNT(*) AS category_count,
    (SUM(catalog_net_loss + web_net_loss) / SUM(total_qty_on_hand)) AS loss_per_qty,
    (SELECT AVG(wr2.wr_return_amt_inc_tax) FROM web_returns wr2) AS global_avg_wr_return_amt_inc_tax
FROM per_store_category
GROUP BY store_id, store_name, year
HAVING SUM(catalog_net_loss + web_net_loss) > (
    SELECT AVG(catalog_net_loss + web_net_loss) FROM per_store_category
)
ORDER BY total_net_loss DESC
LIMIT 100
