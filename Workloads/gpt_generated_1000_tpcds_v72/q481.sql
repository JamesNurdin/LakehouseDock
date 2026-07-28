WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_product_name,
        i.i_units,
        i.i_rec_start_date,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE i.i_units = 'Dozen'
      AND s.s_state = 'CA'
      AND i.i_rec_start_date >= DATE '2001-01-01' AND i.i_rec_start_date < DATE '2002-01-01'
),
agg AS (
    SELECT
        b.s_store_name,
        b.s_state,
        b.i_item_sk,
        b.i_product_name,
        b.hd_income_band_sk,
        SUM(b.ss_net_profit) AS total_net_profit,
        SUM(COALESCE(b.cr_net_loss, 0)) AS total_cr_net_loss,
        SUM(COALESCE(b.sr_net_loss, 0)) AS total_sr_net_loss,
        COUNT(DISTINCT b.ss_ticket_number) AS distinct_tickets
    FROM base b
    GROUP BY GROUPING SETS (
        (b.s_store_name, b.s_state, b.i_item_sk, b.i_product_name, b.hd_income_band_sk),
        (b.s_state, b.hd_income_band_sk),
        ()
    )
)
SELECT
    a.s_store_name,
    a.s_state,
    a.i_product_name,
    a.hd_income_band_sk,
    a.total_net_profit,
    a.total_cr_net_loss,
    a.total_sr_net_loss,
    a.distinct_tickets,
    RANK() OVER (PARTITION BY a.s_state ORDER BY a.total_net_profit DESC) AS profit_rank_state,
    CASE WHEN a.total_cr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS cr_loss_flag
FROM agg a
JOIN catalog_returns cr ON cr.cr_item_sk = a.i_item_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm.sm_carrier = 'DHL'
    )
  AND w.w_state = 'TX'
ORDER BY a.s_state, profit_rank_state
LIMIT 100
