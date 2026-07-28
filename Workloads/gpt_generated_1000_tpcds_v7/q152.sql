WITH base AS (
    SELECT
        s.s_store_name,
        d_ss.d_year,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        ws.ws_net_profit,
        inv.inv_quantity_on_hand,
        cd_s.cd_purchase_estimate,
        p.p_discount_active
    FROM store_sales ss
    INNER JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd_s
        ON ss.ss_cdemo_sk = cd_s.cd_demo_sk
    INNER JOIN household_demographics hd_s
        ON ss.ss_hdemo_sk = hd_s.hd_demo_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT OUTER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d_ss.d_date_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    INNER JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    INNER JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    INNER JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    INNER JOIN customer_demographics cd_r
        ON sr.sr_cdemo_sk = cd_r.cd_demo_sk
    INNER JOIN household_demographics hd_r
        ON sr.sr_hdemo_sk = hd_r.hd_demo_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    INNER JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    INNER JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    INNER JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    INNER JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    INNER JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    INNER JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    INNER JOIN customer_demographics cd_ws_ship
        ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    INNER JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    INNER JOIN income_band ib
        ON hd_s.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_ss.d_year = 2001
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        SUM(ss_net_profit) AS store_sales_profit,
        SUM(sr_net_loss) AS store_returns_loss,
        SUM(cr_net_loss) AS catalog_returns_loss,
        SUM(ws_net_profit) AS web_sales_profit,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS inventory_on_hand
    FROM base
    GROUP BY s_store_name, d_year
)
SELECT
    s_store_name AS store_name,
    d_year AS year,
    store_sales_profit,
    store_returns_loss,
    catalog_returns_loss,
    web_sales_profit,
    inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY store_sales_profit DESC) AS sales_rank
FROM agg
ORDER BY store_sales_profit DESC
LIMIT 100
