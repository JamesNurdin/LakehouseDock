WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_fee,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        sm.sm_ship_mode_id,
        sm.sm_type AS ship_type,
        wh.w_warehouse_name,
        wh.w_city AS warehouse_city,
        hd_rfd.hd_income_band_sk AS hd_refunded_income_band,
        hd_ret.hd_income_band_sk AS hd_returning_income_band,
        ib_ref.ib_lower_bound AS refunded_income_lower,
        ib_ref.ib_upper_bound AS refunded_income_upper,
        ib_ret.ib_lower_bound AS returning_income_lower,
        ib_ret.ib_upper_bound AS returning_income_upper,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        d_cr.d_year,
        d_cr.d_month_seq,
        d_cr.d_date,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss AS sr_net_loss,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        inv.inv_item_sk,
        ws.web_name,
        ws.web_open_date_sk,
        ws.web_close_date_sk
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN household_demographics hd_rfd
        ON cr.cr_refunded_hdemo_sk = hd_rfd.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ref
        ON hd_rfd.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN income_band ib_ret
        ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_cr.d_date_sk
        AND sr.sr_hdemo_sk = hd_rfd.hd_demo_sk
        AND sr.sr_addr_sk = ca_ref.ca_address_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
        AND inv.inv_date_sk = d_cr.d_date_sk
    JOIN date_dim d_ws
        ON cp.cp_start_date_sk = d_ws.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND cp2.cp_type = 'promo'
    )
    AND d_cr.d_year = 2001
),
agg AS (
    SELECT
        w_warehouse_name,
        d_year,
        d_month_seq,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(CASE WHEN cr_return_amount > 0 THEN cr_return_amount ELSE 0 END) AS positive_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY w_warehouse_name, d_year, d_month_seq
)
SELECT
    w_warehouse_name,
    d_year,
    d_month_seq,
    total_return_amount,
    positive_return_amount,
    total_net_loss,
    total_quantity_on_hand,
    txn_count,
    RANK() OVER (ORDER BY total_return_amount DESC) AS warehouse_rank,
    SUM(total_return_amount) OVER (PARTITION BY w_warehouse_name) AS cumulative_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
