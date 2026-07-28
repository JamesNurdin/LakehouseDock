WITH agg_inventory AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    cs.cs_order_number,
    d_cs.d_year,
    cs.cs_net_paid_inc_tax,
    RANK() OVER (PARTITION BY d_cs.d_year ORDER BY cs.cs_net_paid_inc_tax DESC) AS sales_rank_year,
    CASE WHEN sm_cs.sm_carrier = 'UPS' THEN 'Fast' ELSE 'Other' END AS carrier_type,
    inv.total_qty,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = cs.cs_promo_sk) AS avg_promo_cost,
    cs.cs_quantity,
    ws.ws_net_paid_inc_tax AS web_net_paid,
    sr.sr_net_loss
FROM
    catalog_sales cs
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
-- Catalog returns
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
-- Store sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
   AND ss.ss_sold_time_sk = t_cs.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
-- Store returns
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
-- Web sales
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cs.d_date_sk
   AND ws.ws_sold_time_sk = t_cs.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
-- Aggregated inventory
JOIN agg_inventory inv
    ON inv.inv_date_sk = d_cs.d_date_sk
WHERE
    d_cs.d_year = 2001
    AND t_cs.t_hour BETWEEN 8 AND 17
    AND sm_cs.sm_carrier = 'UPS'
    AND p_cs.p_discount_active = 'Y'
    AND c_bill.c_preferred_cust_flag = 'Y'
    AND cs.cs_net_paid_inc_tax > 1000
    AND inv.total_qty > 0
ORDER BY
    sales_rank_year,
    cs.cs_net_paid_inc_tax DESC
LIMIT 100
