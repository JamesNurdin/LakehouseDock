SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_country,
    d_sold.d_year,
    d_sold.d_moy AS month,
    CONCAT(CAST(d_sold.d_year AS VARCHAR), '-', LPAD(CAST(d_sold.d_moy AS VARCHAR), 2, '0')) AS year_month,
    c_sales.c_birth_country,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    COUNT(DISTINCT c_sales.c_customer_sk) AS num_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_quantity_returned,
    CASE WHEN SUM(ss.ss_quantity) > 0 THEN
        COALESCE(SUM(wr.wr_return_quantity), 0) * 1.0 / SUM(ss.ss_quantity)
    ELSE 0 END AS return_rate,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    CASE WHEN s.s_closed_date_sk = d_sold.d_date_sk THEN 1 ELSE 0 END AS store_closed_on_sale_date,
    MIN(d_ship.d_date) AS first_ship_date,
    MIN(d_first_sales.d_date) AS first_sales_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c_sales
    ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c_sales.c_customer_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_ship
    ON c_sales.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_first_sales
    ON c_sales.c_first_sales_date_sk = d_first_sales.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_country,
    d_sold.d_year,
    d_sold.d_moy,
    c_sales.c_birth_country,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END,
    CASE WHEN s.s_closed_date_sk = d_sold.d_date_sk THEN 1 ELSE 0 END,
    CONCAT(CAST(d_sold.d_year AS VARCHAR), '-', LPAD(CAST(d_sold.d_moy AS VARCHAR), 2, '0'))
ORDER BY net_sales_after_returns DESC
LIMIT 100
