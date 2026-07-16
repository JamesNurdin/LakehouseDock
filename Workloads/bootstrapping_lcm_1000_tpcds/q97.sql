SELECT
    t.s_store_id,
    t.s_store_name,
    t.s_state,
    t.s_city,
    t.r_reason_desc,
    t.d_year,
    t.total_net_loss,
    t.total_return_amount,
    t.avg_return_qty,
    t.distinct_refunded_customers,
    t.distinct_returning_customers,
    t.earliest_refunded_first_shipto_date,
    t.latest_returning_first_sales_date,
    t.preferred_refunded_count,
    t.preferred_returning_count
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        r.r_reason_desc,
        d_return.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT c_refunded.c_customer_sk) AS distinct_refunded_customers,
        COUNT(DISTINCT c_returning.c_customer_sk) AS distinct_returning_customers,
        MIN(d_shipto_refunded.d_date) AS earliest_refunded_first_shipto_date,
        MAX(d_sales_returning.d_date) AS latest_returning_first_sales_date,
        SUM(CASE WHEN c_refunded.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_refunded_count,
        SUM(CASE WHEN c_returning.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_returning_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d_return
      ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c_refunded
      ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
      ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN store s
      ON s.s_closed_date_sk = d_return.d_date_sk
    JOIN date_dim d_shipto_refunded
      ON c_refunded.c_first_shipto_date_sk = d_shipto_refunded.d_date_sk
    JOIN date_dim d_sales_refunded
      ON c_refunded.c_first_sales_date_sk = d_sales_refunded.d_date_sk
    JOIN date_dim d_review_refunded
      ON c_refunded.c_last_review_date = d_review_refunded.d_date_sk
    JOIN date_dim d_shipto_returning
      ON c_returning.c_first_shipto_date_sk = d_shipto_returning.d_date_sk
    JOIN date_dim d_sales_returning
      ON c_returning.c_first_sales_date_sk = d_sales_returning.d_date_sk
    JOIN date_dim d_review_returning
      ON c_returning.c_last_review_date = d_review_returning.d_date_sk
    WHERE d_return.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_city,
        r.r_reason_desc,
        d_return.d_year
) t
WHERE t.total_net_loss > 1000
  AND t.rn = 1
ORDER BY t.total_net_loss DESC
LIMIT 100
