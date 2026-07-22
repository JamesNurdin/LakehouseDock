WITH sales_data AS (
    SELECT
        s.s_store_name,
        s.s_rec_start_date,
        s.s_state,
        cd.cd_gender,
        we.web_name,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ws.ws_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.inv_quantity_on_hand
    FROM
        store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        s.s_store_name IN ('pri', 'able')
        AND s.s_rec_start_date >= DATE '2000-01-01'
        AND ws.ws_sales_price > 50
        AND i.inv_quantity_on_hand > 600
)
SELECT
    s_store_name,
    web_name,
    cd_gender,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(ws_net_profit) AS total_net_profit,
    (SUM(sr_net_loss) + SUM(wr_net_loss)) AS total_net_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty
FROM
    sales_data
GROUP BY
    s_store_name,
    web_name,
    cd_gender
ORDER BY
    total_sales DESC
LIMIT 100
