WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        d1.d_fy_year,
        i1.i_item_id,
        i1.i_product_name,
        p1.p_promo_name
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
    JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
)
SELECT
    base.d_fy_year AS fiscal_year,
    base.i_item_id,
    base.i_product_name,
    base.p_promo_name,
    SUM(base.ss_net_profit) AS total_store_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(cr.cr_return_quantity) AS catalog_return_count
FROM base_sales base
JOIN store_returns sr
    ON sr.sr_ticket_number = base.ss_ticket_number
   AND sr.sr_item_sk = base.ss_item_sk
JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = base.ss_item_sk
JOIN date_dim d3 ON cr.cr_returned_date_sk = d3.d_date_sk
JOIN time_dim t3 ON cr.cr_returned_time_sk = t3.t_time_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
JOIN household_demographics hd3 ON cr.cr_refunded_hdemo_sk = hd3.hd_demo_sk
JOIN household_demographics hd4 ON cr.cr_returning_hdemo_sk = hd4.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = base.ss_item_sk
JOIN date_dim d4 ON ws.ws_sold_date_sk = d4.d_date_sk
JOIN time_dim t4 ON ws.ws_sold_time_sk = t4.t_time_sk
JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
JOIN household_demographics hd5 ON ws.ws_bill_hdemo_sk = hd5.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = base.ss_item_sk
JOIN date_dim d5 ON wr.wr_returned_date_sk = d5.d_date_sk
JOIN time_dim t5 ON wr.wr_returned_time_sk = t5.t_time_sk
JOIN household_demographics hd6 ON wr.wr_refunded_hdemo_sk = hd6.hd_demo_sk
JOIN inventory inv
    ON inv.inv_item_sk = base.ss_item_sk
JOIN date_dim d6 ON inv.inv_date_sk = d6.d_date_sk
JOIN warehouse w3 ON inv.inv_warehouse_sk = w3.w_warehouse_sk
GROUP BY
    base.d_fy_year,
    base.i_item_id,
    base.i_product_name,
    base.p_promo_name
ORDER BY fiscal_year DESC, total_store_profit DESC
LIMIT 100
