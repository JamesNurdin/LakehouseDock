WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr_return
        ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
    WHERE s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND we.web_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          JOIN date_dim d_cp
                ON cp.cp_start_date_sk = d_cp.d_date_sk
          WHERE d_cp.d_year = d_sales.d_year
            AND cp.cp_type = 'PROMO'
      )
    GROUP BY s.s_store_id, s.s_store_name, d_sales.d_year
)
SELECT
    DISTINCT b.s_store_id,
    b.s_store_name,
    b.d_year,
    b.total_net_profit,
    b.distinct_transactions,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_net_profit DESC) AS profit_rank
FROM base b
ORDER BY b.total_net_profit DESC
LIMIT 100
