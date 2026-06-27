SELECT
    store.s_store_id,
    store.s_store_name,
    date_dim.d_year,
    date_dim.d_month_seq AS month,
    SUM(store_returns.sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    COUNT(DISTINCT customer.c_customer_id) AS distinct_customers
FROM store_returns
JOIN store
    ON store_returns.sr_store_sk = store.s_store_sk
JOIN date_dim
    ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
JOIN customer
    ON store_returns.sr_customer_sk = customer.c_customer_sk
WHERE date_dim.d_year = 2022
GROUP BY
    store.s_store_id,
    store.s_store_name,
    date_dim.d_year,
    date_dim.d_month_seq
ORDER BY total_net_loss DESC
