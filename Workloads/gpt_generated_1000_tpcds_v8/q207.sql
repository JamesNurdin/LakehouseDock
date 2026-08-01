WITH sampled_sales AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    intersect_orders AS (
        SELECT cs_order_number AS order_number
        FROM sampled_sales
        WHERE cs_quantity > 1
        INTERSECT
        SELECT wr_order_number
        FROM web_returns
        WHERE wr_return_quantity > 0
    ),
    joined AS (
        SELECT
            ss.cs_order_number,
            ss.cs_net_paid_inc_ship_tax,
            ss.cs_wholesale_cost,
            ss.cs_ext_discount_amt,
            wr.wr_return_amt,
            wr.wr_return_quantity,
            i.i_item_id,
            i.i_class,
            cp.cp_department,
            d.d_year,
            ws.web_state
        FROM sampled_sales ss
        JOIN date_dim d
            ON ss.cs_sold_date_sk = d.d_date_sk
        JOIN item i
            ON ss.cs_item_sk = i.i_item_sk
        JOIN catalog_page cp
            ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN web_returns wr
            ON ss.cs_item_sk = wr.wr_item_sk
            AND ss.cs_sold_date_sk = wr.wr_returned_date_sk
        JOIN web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        WHERE
            d.d_year = 1998
            AND i.i_class_id IN (6, 7, 10)
            AND cp.cp_department = 'Sports'
            AND ws.web_state = 'CA'
            AND wr.wr_return_amt > 500
            AND ss.cs_order_number IN (SELECT order_number FROM intersect_orders)
    )
SELECT
    d_year,
    cp_department,
    i_class,
    web_state,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    COUNT(DISTINCT wr_return_quantity) AS distinct_return_qty,
    SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs_wholesale_cost) AS avg_wholesale_cost,
    MIN(cs_ext_discount_amt) AS min_discount,
    MAX(wr_return_amt) AS max_return_amt
FROM joined
GROUP BY d_year, cp_department, i_class, web_state
ORDER BY total_net_paid DESC
LIMIT 100
