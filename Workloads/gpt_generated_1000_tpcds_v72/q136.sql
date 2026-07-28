/*
Goal: Identify high‑value items by combining sales, store returns, web returns and current inventory. The query aggregates sales and return amounts per item, warehouse and catalog page, filters on price, income band, sales hour and a specific return reason, then orders by total sales.
*/
WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    w.w_warehouse_name,
    cp.cp_catalog_page_number,
    SUM(cs.cs_ext_sales_price)                AS total_sales,
    SUM(sr.sr_return_amt)                     AS total_store_return,
    SUM(wr.wr_return_amt)                     AS total_web_return,
    ia.total_qty_on_hand,
    AVG(cs.cs_net_profit)                     AS avg_net_profit
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN time_dim td_sales
    ON cs.cs_sold_time_sk = td_sales.t_time_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
-- Store returns side
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN time_dim td_store_return
    ON sr.sr_return_time_sk = td_store_return.t_time_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
-- Web returns side
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_wr_ref
    ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN household_demographics hd_wr_ret
    ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN customer_address ca_wr_ref
    ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN customer_address ca_wr_ret
    ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
JOIN time_dim td_web_return
    ON wr.wr_returned_time_sk = td_web_return.t_time_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
-- Inventory aggregation
JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
    AND ia.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    i.i_current_price > 20
    AND ib.ib_upper_bound >= 20000
    AND td_sales.t_hour BETWEEN 9 AND 18
    AND r_sr.r_reason_desc = 'Damaged'
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    w.w_warehouse_name,
    cp.cp_catalog_page_number,
    ia.total_qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
