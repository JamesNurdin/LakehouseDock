WITH returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        t.t_hour AS return_hour,
        d_store.d_year AS store_closed_year,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT cust_ret.c_customer_sk) AS distinct_returning_customers,
        MIN(d_sales.d_year) AS first_sales_year,
        MIN(d_shipto.d_month_seq) AS first_shipto_month_seq,
        MIN(d_last_review.d_year) AS last_review_year
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer cust_ref
        ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer cust_ret
        ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    JOIN store s
        ON TRUE
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN date_dim d_shipto
        ON cust_ret.c_first_shipto_date_sk = d_shipto.d_date_sk
    JOIN date_dim d_sales
        ON cust_ret.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN date_dim d_last_review
        ON cust_ret.c_last_review_date = d_last_review.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        d_store.d_year
)

SELECT
    s_store_id,
    s_store_name,
    s_city,
    return_year,
    return_month_seq,
    return_hour,
    store_closed_year,
    num_returns,
    total_net_loss,
    total_refunded_cash,
    avg_return_quantity,
    distinct_returning_customers,
    first_sales_year,
    first_shipto_month_seq,
    last_review_year,
    ROW_NUMBER() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS loss_rank
FROM returns_agg
ORDER BY return_year, loss_rank
