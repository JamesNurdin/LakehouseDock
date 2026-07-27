WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cc.cc_name,
    p.p_promo_name,
    CASE WHEN SUM(cs.cs_net_paid) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_indicator,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    SUM(ia.total_on_hand) AS total_inventory_on_hand
FROM
    call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w_sales
        ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c_ret
        ON sr.sr_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret
        ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN inv_agg ia
        ON ia.inv_item_sk = i.i_item_sk
        AND ia.inv_warehouse_sk = w_sales.w_warehouse_sk
GROUP BY
    cc.cc_name,
    p.p_promo_name
ORDER BY
    total_sales_net_paid DESC
LIMIT 100
