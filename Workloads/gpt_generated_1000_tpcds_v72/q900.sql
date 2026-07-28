WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
loss_agg AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
        SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_loss
    FROM store_sales ss
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON i.i_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_cat
        ON t_cat.t_time_sk = cs.cs_sold_time_sk
    JOIN time_dim t_sr
        ON t_sr.t_time_sk = sr.sr_return_time_sk
    JOIN time_dim t_wr
        ON t_wr.t_time_sk = wr.wr_returned_time_sk
    JOIN time_dim t_cr
        ON t_cr.t_time_sk = cr.cr_returned_time_sk
    JOIN time_dim t_ws
        ON t_ws.t_time_sk = ws.ws_sold_time_sk
    JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN store s
        ON s.s_store_sk = ss.ss_store_sk
    JOIN inv_agg ia
        ON ia.inv_item_sk = i.i_item_sk
       AND ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE t_cat.t_hour BETWEEN 8 AND 12
      AND i.i_category = 'Electronics'
      AND r.r_reason_desc LIKE '%size%'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, i.i_item_id
    HAVING SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 0
)
SELECT
    la.c_customer_id,
    la.i_item_id,
    la.catalog_return_loss,
    la.store_return_loss,
    la.web_return_loss,
    la.total_loss,
    RANK() OVER (PARTITION BY la.i_item_id ORDER BY la.total_loss DESC) AS loss_rank,
    (SELECT MAX(w_max.w_warehouse_sq_ft) FROM warehouse w_max) AS max_warehouse_sq_ft
FROM loss_agg la
ORDER BY la.i_item_id, loss_rank
LIMIT 100
