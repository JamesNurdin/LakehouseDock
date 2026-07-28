SELECT
    wh.w_state,
    i.i_category,
    r_sr.r_reason_desc,
    td_sold.t_hour AS sale_hour,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
FROM tpcds.catalog_sales cs
JOIN tpcds.time_dim td_sold ON cs.cs_sold_time_sk = td_sold.t_time_sk
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN tpcds.time_dim td_return ON sr.sr_return_time_sk = td_return.t_time_sk
JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = wh.w_warehouse_sk
JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN tpcds.time_dim td_wr_return ON wr.wr_returned_time_sk = td_wr_return.t_time_sk
JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr_semi
    WHERE wr_semi.wr_item_sk = cs.cs_item_sk
      AND wr_semi.wr_reason_sk = r_sr.r_reason_sk
)
GROUP BY
    wh.w_state,
    i.i_category,
    r_sr.r_reason_desc,
    td_sold.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
