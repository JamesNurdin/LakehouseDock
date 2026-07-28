WITH joined_agg AS (
    SELECT
        d.d_year,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_returns_cnt
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_store_sk = s.s_store_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
     AND wr.wr_reason_sk = r.r_reason_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND sm.sm_type IN ('NEXT DAY', 'EXPRESS')
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
    GROUP BY d.d_year, sm.sm_type
), final_agg AS (
    SELECT
        d_year,
        sm_type,
        (catalog_profit + store_profit + web_profit) AS total_profit,
        inventory_qty,
        catalog_returns_cnt,
        store_returns_cnt,
        web_returns_cnt
    FROM joined_agg
)
SELECT
    fa.d_year,
    fa.sm_type,
    fa.total_profit,
    fa.inventory_qty,
    fa.catalog_returns_cnt,
    fa.store_returns_cnt,
    fa.web_returns_cnt,
    RANK() OVER (PARTITION BY fa.d_year ORDER BY fa.total_profit DESC) AS profit_rank,
    AVG(fa.total_profit) OVER (PARTITION BY fa.d_year) AS avg_profit_per_year
FROM final_agg fa
WHERE fa.total_profit > 1000
ORDER BY fa.d_year, profit_rank
