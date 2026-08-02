WITH
    cr_filtered AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_net_loss,
            cr.cr_refunded_customer_sk,
            cr.cr_return_quantity,
            cr.cr_refunded_addr_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_tax > 50
          AND cr.cr_return_amount > 100
          AND cr.cr_refunded_addr_sk IN (4384760, 5711453, 2317742)
          AND cr.cr_return_quantity >= 1
    ),
    wr_filtered AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_net_loss,
            wr.wr_refunded_customer_sk,
            wr.wr_return_quantity,
            wr.wr_refunded_addr_sk
        FROM web_returns wr
        WHERE wr.wr_refunded_cash > 50
          AND wr.wr_return_amt > 200
          AND wr.wr_return_tax >= 5
          AND wr.wr_return_quantity >= 1
          AND wr.wr_refunded_addr_sk IN (1854347, 2453001)
    ),
    cust_filtered AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            c.c_birth_month,
            c.c_birth_day,
            c.c_salutation,
            c.c_first_sales_date_sk
        FROM customer c
        WHERE c.c_birth_month BETWEEN 1 AND 12
          AND c.c_salutation = 'Mrs.'
          AND c.c_birth_day >= 10
          AND c.c_first_sales_date_sk > 2449000
    ),
    intersect_customers AS (
        SELECT cr_refunded_customer_sk AS c_customer_sk
        FROM cr_filtered
        INTERSECT
        SELECT wr_refunded_customer_sk
        FROM wr_filtered
    ),
    joined_data AS (
        SELECT
            c.c_customer_id,
            c.c_birth_month,
            cr.cr_returned_date_sk,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_net_loss,
            wr.wr_returned_date_sk,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_net_loss
        FROM intersect_customers ic
        JOIN cust_filtered c ON ic.c_customer_sk = c.c_customer_sk
        JOIN cr_filtered cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN wr_filtered wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    ),
    agg_cr_raw AS (
        SELECT
            c_birth_month,
            cr_returned_date_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS cnt_returns
        FROM joined_data
        GROUP BY ROLLUP (c_birth_month, cr_returned_date_sk)
    ),
    agg_cr AS (
        SELECT
            c_birth_month,
            cr_returned_date_sk,
            total_return_amount,
            total_net_loss,
            cnt_returns,
            ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY total_return_amount DESC) AS rn_by_month
        FROM agg_cr_raw
    ),
    agg_wr_raw AS (
        SELECT
            c_birth_month,
            wr_returned_date_sk,
            SUM(wr_return_amt) AS total_return_amount,
            SUM(wr_net_loss) AS total_net_loss,
            COUNT(*) AS cnt_returns
        FROM joined_data
        GROUP BY CUBE (c_birth_month, wr_returned_date_sk)
    ),
    agg_wr AS (
        SELECT
            c_birth_month,
            wr_returned_date_sk,
            total_return_amount,
            total_net_loss,
            cnt_returns,
            ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY total_return_amount DESC) AS rn_by_month
        FROM agg_wr_raw
    ),
    union_agg AS (
        SELECT
            c_birth_month AS birth_month,
            cr_returned_date_sk AS return_date_sk,
            total_return_amount,
            total_net_loss,
            cnt_returns,
            rn_by_month,
            'catalog' AS source
        FROM agg_cr
        UNION
        SELECT
            c_birth_month AS birth_month,
            wr_returned_date_sk AS return_date_sk,
            total_return_amount,
            total_net_loss,
            cnt_returns,
            rn_by_month,
            'web' AS source
        FROM agg_wr
    )
SELECT
    birth_month,
    return_date_sk,
    source,
    total_return_amount,
    total_net_loss,
    cnt_returns,
    rn_by_month,
    CASE
        WHEN total_net_loss > 1000 THEN 'High'
        WHEN total_net_loss > 500 THEN 'Medium'
        ELSE 'Low'
    END AS net_loss_category
FROM union_agg
WHERE rn_by_month <= 5
ORDER BY birth_month ASC, total_return_amount DESC
LIMIT 100
