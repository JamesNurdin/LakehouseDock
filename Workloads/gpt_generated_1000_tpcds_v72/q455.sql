WITH item_return_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        CASE
            WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS return_level
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price BETWEEN 10 AND 500
      AND i.i_class_id IN (1, 2, 3)
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    cp.cp_department,
    w.w_warehouse_name,
    td_ws.t_hour,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    agg.total_return_qty,
    agg.return_level,
    CASE WHEN ws.ws_net_profit < 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY agg.total_return_amount DESC) AS warehouse_return_rank,
    EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_reason_sk = r.r_reason_sk
    ) AS has_matching_web_return
FROM web_sales ws
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_time_sk = td_ws.t_time_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN time_dim td_ret
    ON cr.cr_returned_time_sk = td_ret.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN item i_wr
    ON wr.wr_item_sk = i_wr.i_item_sk
JOIN item_return_agg agg
    ON i.i_item_sk = agg.i_item_sk
WHERE td_ws.t_hour BETWEEN 8 AND 20
  AND i.i_current_price > 20
  AND w.w_state = 'CA'
ORDER BY warehouse_return_rank, ws.ws_net_profit DESC
LIMIT 100
