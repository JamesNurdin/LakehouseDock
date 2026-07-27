WITH sales_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_bill_addr_sk,
        ws_warehouse_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY
        ws_item_sk,
        ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_bill_addr_sk,
        ws_warehouse_sk,
        ws_order_number
)
SELECT
    d.d_year,
    i.i_category,
    ca.ca_state,
    s.s_store_name,
    w.w_warehouse_name,
    SUM(sa.total_sales) AS sum_sales,
    AVG(sa.total_qty) AS avg_quantity,
    COUNT(DISTINCT sa.ws_order_number) AS order_cnt,
    CASE WHEN SUM(sa.total_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
FROM sales_agg sa
JOIN date_dim d ON sa.ws_sold_date_sk = d.d_date_sk
JOIN item i ON sa.ws_item_sk = i.i_item_sk
JOIN customer c ON sa.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sa.ws_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE
    d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND w.w_zip IN ('33604', '35709')
    AND hd.hd_vehicle_count > 0
    AND i.i_current_price BETWEEN 10 AND 100
    AND s.s_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = sa.ws_order_number
          AND wr.wr_return_amt > 0
    )
GROUP BY
    d.d_year,
    i.i_category,
    ca.ca_state,
    s.s_store_name,
    w.w_warehouse_name
ORDER BY
    sum_sales DESC
LIMIT 100
