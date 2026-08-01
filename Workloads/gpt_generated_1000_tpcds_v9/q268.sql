WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d_sales.d_year AS sales_year,
    i.i_brand AS item_brand,
    s.s_store_name AS store_name,
    p.p_promo_name AS promo_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(ia.total_quantity_on_hand) AS total_inventory_quantity
FROM store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib
    ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
-- Store Returns
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN date_dim d_sr_ret
    ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
JOIN time_dim t_sr_ret
    ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
-- Catalog Returns
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr_ret
    ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN time_dim t_cr_ret
    ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN household_demographics hd_cr_refunded
    ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN household_demographics hd_cr_returning
    ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
-- Web Sales
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship
    ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN date_dim d_web_open
    ON web.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
    ON web.web_close_date_sk = d_web_close.d_date_sk
-- Inventory Aggregated
JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
JOIN date_dim d_inv
    ON ia.inv_date_sk = d_inv.d_date_sk
WHERE d_sales.d_year = 2002
GROUP BY
    d_sales.d_year,
    i.i_brand,
    s.s_store_name,
    p.p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
