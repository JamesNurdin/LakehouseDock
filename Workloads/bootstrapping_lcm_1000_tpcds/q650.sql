SELECT
    s.s_store_name,
    d_ret.d_year,
    CASE WHEN s.s_market_desc = 'Online' THEN 'Online' ELSE 'Offline' END AS market_type,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_count,
    SUM(cr.cr_net_loss) AS catalog_total_net_loss,
    SUM(sr.sr_net_loss) AS store_total_net_loss,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_store_customers,
    CASE
        WHEN SUM(cr.cr_return_quantity) > 100 THEN 'High Catalog Qty'
        ELSE 'Low Catalog Qty'
    END AS catalog_quantity_category,
    ROUND(SUM(sr.sr_return_amt_inc_tax) / NULLIF(SUM(cr.cr_return_amt_inc_tax), 0), 2) AS store_to_catalog_return_ratio
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer c_store ON sr.sr_customer_sk = c_store.c_customer_sk
WHERE d_ret.d_year = 2022
GROUP BY
    s.s_store_name,
    d_ret.d_year,
    CASE WHEN s.s_market_desc = 'Online' THEN 'Online' ELSE 'Offline' END
HAVING SUM(cr.cr_return_quantity) > 0
ORDER BY s.s_store_name
LIMIT 100
