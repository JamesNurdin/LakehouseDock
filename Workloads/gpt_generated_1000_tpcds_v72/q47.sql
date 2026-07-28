WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk
    FROM tpcds.catalog_sales cs
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    cc.cc_name,
    SUM(cs.cs_net_profit)              AS catalog_profit,
    SUM(ss.ss_net_profit)              AS store_profit,
    SUM(ws.ws_net_profit)              AS web_profit,
    SUM(cr.cr_net_loss)                AS catalog_return_loss,
    SUM(sr.sr_net_loss)                AS store_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM base cs
JOIN tpcds.date_dim d            ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.catalog_returns cr   ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN tpcds.reason r_cr           ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN tpcds.store_sales ss       ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN tpcds.reason r_sr           ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN tpcds.web_sales ws        ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    d.d_year = 2001
    AND w.w_country = 'United States'
    AND cd.cd_credit_rating = 'High Risk'
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_upper_bound <= 50000
GROUP BY
    d.d_year,
    w.w_warehouse_name,
    cc.cc_name
ORDER BY
    catalog_profit DESC
LIMIT 100
