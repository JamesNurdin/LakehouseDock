WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year
    FROM date_dim d
    WHERE d.d_year = 2001
)
SELECT
    b.d_year,
    s.s_state,
    p.p_channel_event,
    r.r_reason_desc,
    SUM(cr.cr_net_loss)               AS total_catalog_net_loss,
    SUM(wr.wr_net_loss)               AS total_web_return_net_loss,
    SUM(ws.ws_net_profit)             AS total_web_sales_profit,
    SUM(inv.inv_quantity_on_hand)     AS total_inventory_on_hand,
    COUNT(DISTINCT c.c_customer_sk)   AS distinct_customers,
    COUNT(DISTINCT wsit.web_site_sk)  AS distinct_web_sites
FROM base b
LEFT JOIN catalog_returns cr      ON cr.cr_returned_date_sk = b.d_date_sk
LEFT JOIN reason r                ON cr.cr_reason_sk      = r.r_reason_sk
LEFT JOIN customer c              ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca     ON cr.cr_refunded_addr_sk     = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk   = cd.cd_demo_sk
LEFT JOIN warehouse w             ON cr.cr_warehouse_sk        = w.w_warehouse_sk
LEFT JOIN time_dim t              ON cr.cr_returned_time_sk    = t.t_time_sk
LEFT JOIN store s                 ON s.s_closed_date_sk = b.d_date_sk
LEFT JOIN web_returns wr          ON wr.wr_returned_date_sk = b.d_date_sk
LEFT JOIN web_sales ws            ON ws.ws_sold_date_sk = b.d_date_sk
LEFT JOIN promotion p             ON p.p_start_date_sk = b.d_date_sk
LEFT JOIN inventory inv           ON inv.inv_date_sk = b.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp             ON wp.wp_creation_date_sk = b.d_date_sk
LEFT JOIN web_site wsit            ON wsit.web_open_date_sk = b.d_date_sk
WHERE p.p_channel_event = 'N'
  AND r.r_reason_desc = 'Customer not satisfied'
  AND s.s_state = 'CA'
GROUP BY b.d_year, s.s_state, p.p_channel_event, r.r_reason_desc
ORDER BY total_catalog_net_loss DESC
OFFSET 0 LIMIT 100
