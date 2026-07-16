SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    s.s_division_name,
    s.s_number_employees,
    d_sales.d_year AS sales_year,
    d_sales.d_moy AS sales_month,
    d_store_closed.d_year AS store_closed_year,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    SUM(cs.cs_ext_tax) AS total_sales_tax,
    SUM(cs.cs_ext_ship_cost) AS total_sales_shipping_cost,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_quantity,
    SUM(cr.cr_return_tax) AS total_catalog_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_catalog_return_shipping,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_quantity,
    SUM(sr.sr_return_tax) AS total_store_return_tax,
    SUM(sr.sr_return_ship_cost) AS total_store_return_shipping,
    CASE
        WHEN SUM(cs.cs_net_profit) <> 0 THEN SUM(cr.cr_net_loss) / SUM(cs.cs_net_profit)
        ELSE NULL
    END AS catalog_return_loss_ratio,
    CASE
        WHEN SUM(cs.cs_net_profit) <> 0 THEN SUM(sr.sr_net_loss) / SUM(cs.cs_net_profit)
        ELSE NULL
    END AS store_return_loss_ratio,
    CASE
        WHEN s.s_number_employees > 0 THEN SUM(cs.cs_net_profit) / s.s_number_employees
        ELSE NULL
    END AS profit_per_employee,
    SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales_revenue
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sr_return.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sales.d_year >= 2000
GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    s.s_division_name,
    s.s_number_employees,
    d_sales.d_year,
    d_sales.d_moy,
    d_store_closed.d_year
ORDER BY total_sales_net_profit DESC
LIMIT 100
