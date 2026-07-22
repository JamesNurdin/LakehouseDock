WITH returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        s.s_store_name,
        dd_ret.d_date,
        dd_ret.d_year,
        cp.cp_catalog_page_id,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_date_sk = dd_ret.d_date_sk
        ) AS total_inventory_on_date
    FROM catalog_returns cr
    JOIN date_dim dd_ret ON cr.cr_returned_date_sk = dd_ret.d_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN income_band ib_refund ON hd_refund.hd_income_band_sk = ib_refund.ib_income_band_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN income_band ib_return ON hd_return.hd_income_band_sk = ib_return.ib_income_band_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = dd_ret.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = dd_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dd_ret.d_date_sk AND wp.wp_access_date_sk = dd_ret.d_date_sk
    WHERE dd_ret.d_year = 2001
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND wp.wp_image_count > 3
      AND inv.inv_quantity_on_hand > 0
      AND r.r_reason_desc LIKE '%damage%'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_state,
        s.s_store_name,
        dd_ret.d_date,
        dd_ret.d_year,
        cp.cp_catalog_page_id,
        r.r_reason_desc,
        dd_ret.d_date_sk
)
SELECT
    ra.cc_call_center_id,
    ra.s_store_name,
    ra.d_date,
    ra.cp_catalog_page_id,
    ra.r_reason_desc,
    ra.total_net_loss,
    ra.total_return_qty,
    ra.return_cnt,
    ra.total_inventory_on_date,
    RANK() OVER (PARTITION BY ra.cc_call_center_id ORDER BY ra.total_net_loss DESC) AS net_loss_rank,
    CASE
        WHEN ra.total_net_loss > (SELECT AVG(total_net_loss) FROM returns_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_vs_average
FROM returns_agg ra
ORDER BY ra.cc_call_center_id, net_loss_rank
LIMIT 100
