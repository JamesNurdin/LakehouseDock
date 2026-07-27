WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
    FROM tpcds.catalog_sales cs
)
SELECT
    i.i_category,
    d_sold.d_year,
    COUNT(DISTINCT base.cs_order_number) AS distinct_orders,
    SUM(base.cs_net_profit) AS total_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_return_loss,
    COALESCE(SUM(sr.sr_net_loss), 0) AS store_return_loss
FROM base
JOIN tpcds.date_dim d_sold ON base.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship ON base.cs_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.item i ON base.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p ON base.cs_promo_sk = p.p_promo_sk
JOIN tpcds.call_center cc ON base.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w ON base.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_demographics cd_bill ON base.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship ON base.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_bill ON base.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship ON base.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.catalog_returns cr ON cr.cr_order_number = base.cs_order_number
LEFT JOIN tpcds.date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
LEFT JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_ss_sold ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
LEFT JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN tpcds.date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
LEFT JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
GROUP BY
    i.i_category,
    d_sold.d_year
ORDER BY total_profit DESC
LIMIT 100
