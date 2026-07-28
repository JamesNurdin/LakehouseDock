WITH distinct_reason AS (
    SELECT DISTINCT r.r_reason_sk
    FROM reason r
    WHERE r.r_reason_desc LIKE '%size%'
)
SELECT
    d_sales.d_year,
    i.i_category,
    i.i_brand,
    SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 10000 THEN 'High'
        WHEN SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank,
    MAX(cc.cc_name)               AS call_center_name,
    MAX(sm.sm_type)               AS ship_type,
    MAX(wp.wp_url)                AS web_page_url,
    MAX(ws.web_name)              AS website_name,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sale
    ON ss.ss_sold_time_sk = t_sale.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
WHERE d_sales.d_year = 2001
  AND i.i_size IN ('small', 'medium')
  AND i.i_current_price > 20
  AND cc.cc_state = 'CA'
  AND cr.cr_reason_sk IN (SELECT r_reason_sk FROM distinct_reason)
GROUP BY d_sales.d_year, i.i_category, i.i_brand
ORDER BY total_net_loss DESC
LIMIT 100
