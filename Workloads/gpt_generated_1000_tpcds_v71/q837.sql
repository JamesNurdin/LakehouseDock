WITH avg_catalog_return AS (
    SELECT AVG(cr2.cr_return_amount) AS avg_ret_amount
    FROM catalog_returns cr2
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cc.cc_state,
    td.t_hour,
    SUM(cr.cr_return_amount)                           AS total_catalog_return_amount,
    SUM(wr.wr_return_amt)                              AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number)                 AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number)                 AS web_orders,
    AVG(cr.cr_return_tax)                              AS avg_catalog_return_tax,
    MAX(wr.wr_net_loss)                                AS max_web_net_loss,
    COALESCE(inv.inv_quantity_on_hand, 0)              AS inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rn_item,
    SUM(cr.cr_return_amount) - (SELECT avg_ret_amount FROM avg_catalog_return) AS diff_from_avg_catalog_return
FROM
    catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    -- Web return side
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
WHERE
    c_refunded.c_birth_year = 1960
    AND i.i_wholesale_cost > 5.00
    AND cc.cc_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
    AND cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2005-12-31'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cc.cc_state,
    td.t_hour,
    inv.inv_quantity_on_hand
ORDER BY
    total_catalog_return_amount DESC
LIMIT 100
