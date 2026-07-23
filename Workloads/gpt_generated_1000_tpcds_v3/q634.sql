WITH filtered_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        ws.web_name,
        cc.cc_name,
        cu.c_customer_sk,
        cu.c_birth_month,
        d.d_year,
        d.d_current_year,
        d.d_current_month
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer cu
        ON cr.cr_refunded_customer_sk = cu.c_customer_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE ws.web_country = 'United States'
      AND ws.web_rec_start_date >= DATE '1999-01-01'
      AND cc.cc_state = 'NY'
      AND cu.c_birth_month = 5
      AND d.d_year = 2000
      AND cr.cr_return_amount > 100.0
)
SELECT
    fd.web_name,
    fd.cc_name,
    fd.d_year,
    SUM(fd.cr_return_amount) AS total_return_amount,
    AVG(fd.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_count,
    MAX(fd.cr_return_quantity) AS max_return_quantity,
    MIN(fd.cr_return_quantity) AS min_return_quantity,
    COUNT(DISTINCT fd.c_customer_sk) AS distinct_customers
FROM filtered_data fd
GROUP BY fd.web_name, fd.cc_name, fd.d_year
ORDER BY total_return_amount DESC
LIMIT 100
