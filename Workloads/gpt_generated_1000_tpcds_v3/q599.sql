WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        i.i_category,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_net_loss AS cr_net_loss,
        inv.inv_quantity_on_hand AS inv_qty
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    -- catalog returns and its related dimensions
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_returned_time_sk = t.t_time_sk
     AND cr.cr_item_sk = i.i_item_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
     AND cr.cr_refunded_addr_sk = ca.ca_address_sk
     AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
     AND cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    -- warehouse linked through catalog returns
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- inventory for the same date/item/warehouse
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    -- web sales linked to the same dimensions
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
     AND ws.ws_ship_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
     AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
     AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
     AND ws.ws_ship_addr_sk = ca.ca_address_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    -- income band for household demographics
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- store and call‑center dates (using the same date_dim alias for simplicity)
    WHERE s.s_closed_date_sk = d.d_date_sk
      AND cc.cc_closed_date_sk = d.d_date_sk
      AND cc.cc_open_date_sk = d.d_date_sk
      -- filter predicates (at least five)
      AND d.d_year = 2001
      AND s.s_state = 'CA'
      AND w.w_zip = '33604'
      AND i.i_brand = 'BrandX'
      AND ca.ca_state = 'TX'
      AND hd.hd_buy_potential = '5000-10000'
)
SELECT
    base.s_store_id,
    base.s_state,
    base.d_year,
    base.i_category,
    SUM(base.ss_net_paid) AS total_store_sales,
    SUM(base.ws_net_paid) AS total_web_sales,
    SUM(base.cr_net_loss) AS total_return_loss,
    AVG(base.inv_qty) AS avg_inventory_qty,
    COUNT(*) AS transaction_count,
    (SUM(base.ss_net_profit) + SUM(base.ws_net_paid) - SUM(base.cr_net_loss)) / NULLIF(COUNT(*), 0) AS avg_profit_per_txn
FROM base
GROUP BY
    base.s_store_id,
    base.s_state,
    base.d_year,
    base.i_category
HAVING
    SUM(base.ss_net_profit) > (
        SELECT AVG(inner_ss.ss_net_profit)
        FROM store_sales inner_ss
        JOIN date_dim inner_d ON inner_ss.ss_sold_date_sk = inner_d.d_date_sk
        WHERE inner_d.d_year = 2001
    )
ORDER BY total_store_sales DESC
LIMIT 100
