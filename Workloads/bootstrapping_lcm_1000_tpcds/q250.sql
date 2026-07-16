WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_store.d_year AS store_closed_year,
        d_store.d_month_seq AS store_closed_month,
        d_cust_sales.d_year AS customer_first_sales_year,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        MAX(d_sr.d_date) AS latest_store_return_date,
        MAX(d_cr.d_date) AS latest_catalog_return_date,
        s.s_market_manager,
        s.s_city
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d_cust_sales ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_store.d_year,
        d_store.d_month_seq,
        d_cust_sales.d_year,
        s.s_market_manager,
        s.s_city
)
SELECT
    s_store_id,
    s_store_name,
    store_closed_year,
    store_closed_month,
    customer_first_sales_year,
    distinct_customers,
    total_store_net_loss,
    total_catalog_net_loss,
    avg_catalog_return_qty,
    latest_store_return_date,
    latest_catalog_return_date,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_net_loss DESC) AS store_loss_rank,
    s_market_manager,
    s_city
FROM store_agg
ORDER BY total_store_net_loss DESC
LIMIT 100
