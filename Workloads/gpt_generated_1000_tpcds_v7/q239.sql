/*
Goal: Produce a multi‑dimensional sales and returns performance snapshot by year, department and warehouse state, incorporating catalog sales, web sales, store returns, catalog returns and demographic income bands. The query joins all 15 selected TPC‑DS tables (using several tables twice under different aliases) with at least nine explicit JOIN clauses, aggregates key monetary metrics, and limits the output to the top 100 rows.
*/
SELECT
    d.d_year,
    cp.cp_department,
    w.w_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_bill.hd_buy_potential,
    SUM(cs.cs_net_profit)               AS total_catalog_net_profit,
    SUM(ws.ws_net_profit)               AS total_web_net_profit,
    SUM(sr.sr_net_loss)                 AS total_store_net_loss,
    SUM(cr.cr_return_amount)            AS total_catalog_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(i.i_current_price)              AS min_item_price,
    MAX(r_cr.r_reason_desc)             AS most_common_catalog_return_reason,
    MAX(r_sr.r_reason_desc)             AS most_common_store_return_reason
FROM
    tpcds.date_dim d
/* 1 */
JOIN tpcds.catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
/* 2 */
JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
/* 3 */
JOIN tpcds.item i
    ON i.i_item_sk = cs.cs_item_sk
/* 4 */
JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
/* 5 */
JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
/* 6 */
JOIN tpcds.web_site ws_site
    ON ws_site.web_open_date_sk = d.d_date_sk
/* 7 */
JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_web_site_sk = ws_site.web_site_sk
/* 8 */
JOIN tpcds.store s
    ON s.s_closed_date_sk = d.d_date_sk
/* 9 */
JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
/* 10 */
JOIN tpcds.household_demographics hd_bill
    ON hd_bill.hd_demo_sk = cs.cs_bill_hdemo_sk
/* 11 */
JOIN tpcds.income_band ib
    ON ib.ib_income_band_sk = hd_bill.hd_income_band_sk
/* 12 */
JOIN tpcds.customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
/* 13 */
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
/* 14 */
JOIN tpcds.reason r_cr
    ON r_cr.r_reason_sk = cr.cr_reason_sk
/* 15 */
JOIN tpcds.reason r_sr
    ON r_sr.r_reason_sk = sr.sr_reason_sk
GROUP BY
    d.d_year,
    cp.cp_department,
    w.w_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_bill.hd_buy_potential
ORDER BY
    d.d_year,
    cp.cp_department,
    w.w_state
LIMIT 100
