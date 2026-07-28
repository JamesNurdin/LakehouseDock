WITH overall_avg AS (
    SELECT avg(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    COALESCE(SUM(cs.cs_net_paid), 0)               AS catalog_net_paid,
    COALESCE(SUM(ss.ss_net_paid), 0)               AS store_net_paid,
    COALESCE(SUM(cr.cr_net_loss), 0)               AS catalog_return_loss,
    COALESCE(SUM(sr.sr_net_loss), 0)               AS store_return_loss,
    COUNT(DISTINCT cs.cs_order_number)             AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number)            AS store_orders,
    oa.avg_discount                                 AS overall_avg_discount,
    wp.wp_url                                       AS web_page_url
FROM item i
LEFT JOIN catalog_sales cs
       ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN time_dim t_cs
       ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN customer c_bill
       ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_demographics cd_bill
       ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_address ca_bill
       ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm_cs
       ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN promotion p_cs
       ON cs.cs_promo_sk = p_cs.p_promo_sk

LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN time_dim t_cr
       ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN ship_mode sm_cr
       ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN customer c_refund
       ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
LEFT JOIN customer_demographics cd_refund
       ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN customer_address ca_refund
       ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN catalog_page cp_cr
       ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk

LEFT JOIN store_sales ss
       ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN time_dim t_ss
       ON ss.ss_sold_time_sk = t_ss.t_time_sk
LEFT JOIN store s
       ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN customer c_store
       ON ss.ss_customer_sk = c_store.c_customer_sk
LEFT JOIN customer_demographics cd_store
       ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
LEFT JOIN customer_address ca_store
       ON ss.ss_addr_sk = ca_store.ca_address_sk
LEFT JOIN promotion p_ss
       ON ss.ss_promo_sk = p_ss.p_promo_sk

LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN time_dim t_sr
       ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN customer c_sr
       ON sr.sr_customer_sk = c_sr.c_customer_sk
LEFT JOIN customer_demographics cd_sr
       ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN customer_address ca_sr
       ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN store s_sr
       ON sr.sr_store_sk = s_sr.s_store_sk

LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN promotion p_item
       ON p_item.p_item_sk = i.i_item_sk

LEFT JOIN web_page wp
       ON wp.wp_customer_sk = c_bill.c_customer_sk

CROSS JOIN overall_avg oa

GROUP BY
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    s.s_state,
    oa.avg_discount,
    wp.wp_url
HAVING
    COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0) > 10000
ORDER BY
    (COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0)) DESC
