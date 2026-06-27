WITH sales AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        td.t_hour BETWEEN 8 AND 17
        AND cp.cp_department = 'Electronics'
    GROUP BY
        i.i_category,
        w.w_warehouse_name
),
returns AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        td.t_hour BETWEEN 8 AND 17
        AND cp.cp_department = 'Electronics'
    GROUP BY
        i.i_category,
        w.w_warehouse_name
)
SELECT
    s.i_category,
    s.w_warehouse_name,
    s.total_sales_profit,
    r.total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    CASE WHEN s.total_quantity_sold > 0 THEN
        COALESCE(r.total_quantity_returned, 0) / CAST(s.total_quantity_sold AS double)
    ELSE 0 END AS return_rate
FROM
    sales s
    LEFT JOIN returns r
        ON s.i_category = r.i_category
        AND s.w_warehouse_name = r.w_warehouse_name
ORDER BY
    net_profit_after_returns DESC
LIMIT 10
