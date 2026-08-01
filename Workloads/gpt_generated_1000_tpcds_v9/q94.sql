SELECT
    c.c_customer_id,
    c.c_customer_sk,
    i.i_item_id,
    r_sr.r_reason_desc,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    AVG(i.i_current_price) AS avg_item_price,
    MAX(ss.ss_ext_discount_amt) AS max_discount_amount,
    (SELECT COUNT(*) FROM inventory) AS total_inventory_records,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM store_returns sr4
            WHERE sr4.sr_customer_sk = c.c_customer_sk
              AND sr4.sr_return_amt > 200
        ) THEN 'HighReturn'
        ELSE 'LowReturn'
    END AS customer_return_category
FROM store_sales ss
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE
    i.i_brand_id = 5
    AND hd.hd_income_band_sk = 8
    AND td_ss.t_hour = 14
    AND c.c_birth_year BETWEEN 1975 AND 1995
    AND inv.inv_quantity_on_hand > 10
GROUP BY GROUPING SETS (
    (c.c_customer_id, c.c_customer_sk, i.i_item_id, r_sr.r_reason_desc),
    (c.c_customer_id, c.c_customer_sk, i.i_item_id),
    (c.c_customer_id, c.c_customer_sk),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
