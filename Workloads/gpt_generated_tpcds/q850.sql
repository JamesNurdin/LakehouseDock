WITH sales_data AS (
    SELECT
        d_sale.d_year AS year,
        d_sale.d_month_seq AS month_seq,
        w.w_state AS warehouse_state,
        hd.hd_buy_potential AS buy_potential,
        wp.wp_type AS page_type,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        COALESCE(wr.wr_return_amt, 0) AS return_amt,
        COALESCE(wr.wr_net_loss, 0) AS return_loss
    FROM web_sales ws
    JOIN date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d_sale.d_date >= DATE '2001-01-01'
      AND d_sale.d_date < DATE '2002-01-01'
)
SELECT
    year,
    month_seq,
    warehouse_state,
    buy_potential,
    page_type,
    sum(ws_ext_sales_price) AS total_sales_amount,
    sum(ws_net_profit) AS total_sales_net_profit,
    sum(return_amt) AS total_return_amount,
    sum(return_loss) AS total_return_loss,
    sum(ws_net_profit) - sum(return_loss) AS net_profit_after_returns
FROM sales_data
GROUP BY year, month_seq, warehouse_state, buy_potential, page_type
ORDER BY year, month_seq, warehouse_state, buy_potential, page_type
