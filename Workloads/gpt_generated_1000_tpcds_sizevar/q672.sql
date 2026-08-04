WITH sales_with_returns AS (
        SELECT
            cs.cs_order_number,
            cs.cs_item_sk,
            cs.cs_ext_sales_price,
            cs.cs_ext_tax,
            cr.cr_return_amount,
            cr.cr_return_tax,
            c_bill.c_customer_sk,
            c_bill.c_first_name,
            c_bill.c_last_name,
            ca_bill.ca_state,
            CASE WHEN cr.cr_return_amount > 0 THEN 'RETURN' ELSE 'SALE' END AS sale_type
        FROM catalog_sales cs
        JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
           AND cs.cs_item_sk = cr.cr_item_sk
        RIGHT OUTER JOIN customer c_bill
            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
        LEFT JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer c_ship
            ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
        LEFT JOIN customer_address ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    ),
    web_sales_with_returns AS (
        SELECT
            ws.ws_order_number,
            ws.ws_item_sk,
            ws.ws_ext_sales_price,
            ws.ws_ext_tax,
            wr.wr_return_amt,
            wr.wr_return_tax,
            c_bill.c_customer_sk,
            c_bill.c_first_name,
            c_bill.c_last_name,
            ca_bill.ca_state,
            CASE WHEN wr.wr_return_amt > 0 THEN 'RETURN' ELSE 'SALE' END AS sale_type
        FROM web_sales ws
        JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
           AND ws.ws_item_sk = wr.wr_item_sk
        FULL OUTER JOIN customer c_bill
            ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        LEFT JOIN customer_address ca_bill
            ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer c_ship
            ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
        LEFT JOIN customer_address ca_ship
            ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    ),
    intersect_orders AS (
        SELECT cs_order_number AS order_number FROM sales_with_returns
        INTERSECT
        SELECT ws_order_number FROM web_sales_with_returns
    ),
    agg_sales AS (
        SELECT
            ca_state,
            sale_type,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cr_return_amount) AS total_returns,
            COUNT(DISTINCT cs_order_number) AS order_cnt
        FROM sales_with_returns swr
        JOIN intersect_orders io ON swr.cs_order_number = io.order_number
        GROUP BY ca_state, sale_type
    ),
    agg_web AS (
        SELECT
            ca_state,
            sale_type,
            SUM(ws_ext_sales_price) AS total_sales,
            SUM(wr_return_amt) AS total_returns,
            COUNT(DISTINCT ws_order_number) AS order_cnt
        FROM web_sales_with_returns wwr
        JOIN intersect_orders io ON wwr.ws_order_number = io.order_number
        GROUP BY ca_state, sale_type
    )
SELECT
    state,
    sale_type,
    SUM(total_sales) AS combined_sales,
    SUM(total_returns) AS combined_returns,
    SUM(order_cnt) AS combined_orders
FROM (
        SELECT ca_state AS state, sale_type, total_sales, total_returns, order_cnt FROM agg_sales
        UNION DISTINCT
        SELECT ca_state AS state, sale_type, total_sales, total_returns, order_cnt FROM agg_web
     ) u
GROUP BY state, sale_type
ORDER BY combined_sales DESC
LIMIT 100
