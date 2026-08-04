WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sales_year,
        s.s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 2001 AND 2002
    GROUP BY d_sold.d_year, s.s_store_name
),
returns_agg AS (
    SELECT
        d_return.d_year AS return_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT c_refund.c_customer_sk) AS distinct_refund_customers
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    GROUP BY d_return.d_year
),
order_intersect AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
),
order_except AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
)
SELECT
    sa.sales_year,
    sa.s_store_name,
    sa.total_sales,
    sa.total_profit,
    sa.distinct_bill_customers,
    sa.distinct_ship_modes,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.distinct_refund_customers, 0) AS distinct_refund_customers,
    (SELECT COUNT(*) FROM order_intersect) AS intersect_order_count,
    (SELECT COUNT(*) FROM order_except) AS except_order_count
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.sales_year = ra.return_year
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN date_dim d_ret ON wr2.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = sa.sales_year
)
ORDER BY sa.total_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
