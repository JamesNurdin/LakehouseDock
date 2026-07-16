SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_date,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_ext_tax) AS total_tax,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_return_quantity,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_net_loss,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_web_return_quantity,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_net_loss,
    (SUM(ss.ss_net_profit) - (COALESCE(SUM(cr.cr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0))) AS net_contribution,
    CASE WHEN d_closed.d_date_sk = d_sales.d_date_sk THEN 1 ELSE 0 END AS store_closed_on_sale_date,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns,
    CASE WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0 ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) END AS profit_margin,
    CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0 ELSE (COALESCE(SUM(cr.cr_return_quantity), 0) + COALESCE(SUM(wr.wr_return_quantity), 0)) / SUM(ss.ss_quantity) END AS return_rate
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_date,
    d_sales.d_date_sk,
    d_closed.d_date_sk
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
