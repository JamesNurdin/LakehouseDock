WITH inventory_summary AS (
       SELECT
           inv.inv_item_sk,
           inv.inv_warehouse_sk,
           SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
       FROM inventory inv
       GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
   )
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(wr.wr_net_loss), 0)) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(wr.wr_net_loss), 0)) DESC) AS state_store_rank,
    CASE WHEN (SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(wr.wr_net_loss), 0)) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM
    store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_summary inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    s.s_state = 'TX'
    AND ib.ib_upper_bound >= 100000
    AND s.s_rec_start_date >= DATE '2001-01-01'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    total_net_profit DESC
LIMIT 100
