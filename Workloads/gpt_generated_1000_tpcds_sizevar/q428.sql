WITH letters AS (
    SELECT ARRAY['A', 'B', 'C'] AS arr
)
SELECT
    cr.cr_order_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'high' ELSE 'low' END AS return_category,
    r.r_reason_desc,
    t1.t_hour,
    u.letter
FROM
    catalog_returns cr
    JOIN time_dim t1 ON cr.cr_returned_time_sk = t1.t_time_sk
    JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    -- star joins to the other fact tables via the same time dimension
    JOIN store_returns sr ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t1.t_time_sk
    JOIN item i3 ON wr.wr_item_sk = i3.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
    JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
    JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    CROSS JOIN letters lt
    CROSS JOIN UNNEST(lt.arr) AS u(letter)
WHERE
    cr.cr_order_number NOT IN (SELECT sr2.sr_ticket_number FROM store_returns sr2)
GROUP BY
    cr.cr_order_number,
    r.r_reason_desc,
    t1.t_hour,
    u.letter
ORDER BY
    total_return_amount DESC
LIMIT 100
