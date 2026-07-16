SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_start.d_current_month AS start_month,
    d_end.d_year AS end_year,
    d_end.d_current_month AS end_month,
    s.s_store_name,
    s.s_city,
    d_end.d_date AS store_closed_date,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_quantity_returned,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_net_loss,
    (SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0))) AS net_profit_adjusted,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_dates
FROM
    catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_start.d_year,
    d_start.d_current_month,
    d_end.d_year,
    d_end.d_current_month,
    s.s_store_name,
    s.s_city,
    d_end.d_date
ORDER BY
    net_profit_adjusted DESC
LIMIT 100
