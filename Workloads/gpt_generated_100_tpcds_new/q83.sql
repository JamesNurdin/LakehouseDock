WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_qty
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY
        cs_item_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_hdemo_sk
)
SELECT
    d_sold.d_year,
    i.i_item_id,
    i.i_product_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    cs_agg.total_sales,
    cs_agg.total_qty,
    ws.ws_net_profit,
    cr.cr_return_amount,
    wr.wr_return_amt,
    r_store.r_reason_desc AS store_return_reason,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    (SELECT MAX(d_date) FROM tpcds.date_dim) AS max_date_in_dim,
    lr.store_ret_cnt
FROM cs_agg
JOIN tpcds.item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_sold
    ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_sold
    ON cs_agg.cs_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.household_demographics hd
    ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
-- store (joined via the same date dimension used for sales)
JOIN tpcds.store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
-- store returns and its reason
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
-- web sales (joined on the same item and date)
LEFT JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d_sold.d_date_sk
-- web returns and its reason (via the associated web sales order)
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN tpcds.reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
-- catalog returns and its reason
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
-- lateral sub‑query that counts how many store returns exist for the current item
JOIN LATERAL (
    SELECT COUNT(*) AS store_ret_cnt
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_item_sk = i.i_item_sk
) AS lr ON TRUE
WHERE EXISTS (
    SELECT 1
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_order_number = cr.cr_order_number
      AND cs2.cs_item_sk = i.i_item_sk
)
GROUP BY
    d_sold.d_year,
    i.i_item_id,
    i.i_product_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    cs_agg.total_sales,
    cs_agg.total_qty,
    ws.ws_net_profit,
    cr.cr_return_amount,
    wr.wr_return_amt,
    r_store.r_reason_desc,
    r_cr.r_reason_desc,
    r_wr.r_reason_desc,
    lr.store_ret_cnt
ORDER BY d_sold.d_year DESC, cs_agg.total_sales DESC
LIMIT 100
