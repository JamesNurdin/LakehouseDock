WITH
    store_returns_agg AS (
        SELECT
            sr_item_sk,
            sr_return_time_sk,
            SUM(sr_return_quantity) AS total_return_qty,
            SUM(sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM tpcds.store_returns
        GROUP BY sr_item_sk, sr_return_time_sk
    ),
    sales_without_returns AS (
        SELECT ws_order_number
        FROM tpcds.web_sales
        EXCEPT
        SELECT wr_order_number
        FROM tpcds.web_returns
    ),
    joined_data AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            i.i_category,
            i.i_brand,
            sra.total_return_qty,
            cr.cr_return_amount,
            ws.ws_net_paid,
            wr.wr_return_amt,
            COALESCE(sra.total_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) AS row_loss,
            t_sra.t_meal_time,
            ws.ws_quantity,
            cr.cr_return_quantity
        FROM tpcds.item i
        JOIN store_returns_agg sra
            ON i.i_item_sk = sra.sr_item_sk
        JOIN tpcds.time_dim t_sra
            ON sra.sr_return_time_sk = t_sra.t_time_sk
        JOIN tpcds.catalog_returns cr
            ON i.i_item_sk = cr.cr_item_sk
        JOIN tpcds.time_dim t_cr
            ON cr.cr_returned_time_sk = t_cr.t_time_sk
        JOIN tpcds.customer_address ca_cr_refund
            ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
        JOIN tpcds.customer_address ca_cr_return
            ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
        JOIN tpcds.web_sales ws
            ON i.i_item_sk = ws.ws_item_sk
        JOIN tpcds.time_dim t_ws
            ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN tpcds.customer_address ca_ws_bill
            ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN tpcds.customer_address ca_ws_ship
            ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
        JOIN tpcds.web_returns wr
            ON i.i_item_sk = wr.wr_item_sk
           AND ws.ws_order_number = wr.wr_order_number
        JOIN tpcds.time_dim t_wr
            ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN tpcds.customer_address ca_wr_refund
            ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
        JOIN tpcds.customer_address ca_wr_return
            ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
        JOIN sales_without_returns swo
            ON ws.ws_order_number = swo.ws_order_number
        WHERE
            t_sra.t_meal_time IN ('lunch', 'dinner')
            AND i.i_brand = 'Brand#2'
            AND ws.ws_quantity > 5
            AND cr.cr_return_quantity > 15
            AND NOT EXISTS (
                SELECT 1
                FROM tpcds.store_returns sr_excl
                WHERE sr_excl.sr_item_sk = i.i_item_sk
                  AND sr_excl.sr_store_sk = 32
            )
    ),
    item_losses AS (
        SELECT
            jd.*, 
            SUM(jd.row_loss) OVER (PARTITION BY jd.i_item_sk) AS total_loss_per_item
        FROM joined_data jd
    )
SELECT
    il.i_item_id,
    il.i_product_name,
    il.i_category,
    il.i_brand,
    il.total_return_qty,
    il.cr_return_amount,
    il.ws_net_paid,
    il.wr_return_amt,
    il.total_loss_per_item,
    DENSE_RANK() OVER (ORDER BY il.total_loss_per_item DESC) AS loss_rank,
    CASE
        WHEN il.total_loss_per_item > 5000 THEN 'High'
        ELSE 'Medium'
    END AS loss_category,
    (SELECT AVG(ws2.ws_net_paid) FROM tpcds.web_sales ws2 WHERE ws2.ws_item_sk = il.i_item_sk) AS avg_ws_net_paid
FROM item_losses il
ORDER BY il.total_loss_per_item DESC
LIMIT 100
