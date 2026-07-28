WITH sales_agg AS (
    SELECT
        c_bill.c_customer_sk,
        c_bill.c_customer_id,
        d_sold.d_year,
        SUM(ws.ws_net_profit)               AS total_profit,
        SUM(ws.ws_ext_sales_price)          AS total_sales,
        COUNT(DISTINCT ws.ws_order_number)  AS order_cnt
    FROM tpcds.web_sales ws
    -- sold date dimension (alias d_sold)
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    -- ship date dimension (alias d_ship)
    JOIN tpcds.date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    -- billing customer and related dimensions
    JOIN tpcds.customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    -- shipping customer and related dimensions (reuse tables under different aliases)
    JOIN tpcds.customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN tpcds.household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    -- web page
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    -- warehouse
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    -- inventory (joined via warehouse and sold date)
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
       AND i.inv_date_sk = d_sold.d_date_sk
    -- store (joined via ship date closed flag)
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    -- web returns (joined via order number and item)
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d_sold.d_year = 2001
    GROUP BY c_bill.c_customer_sk, c_bill.c_customer_id, d_sold.d_year
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    sa.c_customer_id,
    sa.d_year,
    sa.total_profit,
    sa.total_sales,
    sa.order_cnt,
    (
        SELECT COALESCE(SUM(wr2.wr_return_amt), 0)
        FROM tpcds.web_returns wr2
        JOIN tpcds.web_sales ws2
            ON wr2.wr_order_number = ws2.ws_order_number
        WHERE ws2.ws_bill_customer_sk = sa.c_customer_sk
    ) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank
FROM sales_agg sa
ORDER BY sa.total_profit DESC
LIMIT 100
