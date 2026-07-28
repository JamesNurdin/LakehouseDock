WITH sales_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_warehouse_name AS warehouse_name,
        d_sold.d_year AS year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(wr.wr_net_loss) AS total_return_loss,
        AVG(inv.inv_quantity_on_hand) AS avg_inv_qty,
        MIN(d_sold.d_date) AS first_sale_date,
        MAX(d_return.d_date) AS last_return_date
    FROM web_sales ws
    JOIN date_dim d_sold      ON ws.ws_sold_date_sk   = d_sold.d_date_sk
    JOIN date_dim d_ship      ON ws.ws_ship_date_sk   = d_ship.d_date_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk  = w.w_warehouse_sk
    JOIN web_returns wr      ON ws.ws_order_number  = wr.wr_order_number
                               AND ws.ws_item_sk      = wr.wr_item_sk
    JOIN date_dim d_return    ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN inventory inv        ON w.w_warehouse_sk    = inv.inv_warehouse_sk
                               AND inv.inv_date_sk    = d_sold.d_date_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship       ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_refund     ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return     ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
    JOIN call_center cc                ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp                ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND w.w_state = 'CA'
        AND cc.cc_call_center_id = 'AAAAAAAANAAAAAAA'
        AND cp.cp_catalog_number = 3
        AND inv.inv_quantity_on_hand > 500
        AND hd_bill.hd_vehicle_count >= 2
        AND wr.wr_reversed_charge > 100
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        d_sold.d_year
)
SELECT
    warehouse_id,
    warehouse_name,
    year,
    total_profit,
    order_cnt,
    total_return_loss,
    avg_inv_qty,
    first_sale_date,
    last_return_date,
    ROW_NUMBER() OVER (PARTITION BY warehouse_id ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
