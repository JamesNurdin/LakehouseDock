WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
combined_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        sr.sr_return_amt,
        'Store' AS return_source,
        CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_flag,
        (
            SELECT avg(cs.cs_net_paid_inc_ship_tax)
            FROM catalog_sales cs
            WHERE cs.cs_bill_customer_sk = c.c_customer_sk
        ) AS avg_spent
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_date_sk IN (SELECT d_date_sk FROM recent_dates)
      AND s.s_company_name = 'Unknown'
),
web_combined AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        wr.wr_return_amt,
        'Web' AS return_source,
        CASE WHEN wr.wr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_flag,
        (
            SELECT avg(cs.cs_net_paid_inc_ship_tax)
            FROM catalog_sales cs
            WHERE cs.cs_bill_customer_sk = c.c_customer_sk
        ) AS avg_spent
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_date_sk IN (SELECT d_date_sk FROM recent_dates)
      AND wp.wp_type = 'home'
)
SELECT
    c_customer_id,
    return_source,
    return_amt,
    loss_flag,
    avg_spent
FROM (
    SELECT c_customer_sk, c_customer_id, sr_return_amt AS return_amt, return_source, loss_flag, avg_spent
    FROM combined_returns
    UNION
    SELECT c_customer_sk, c_customer_id, wr_return_amt AS return_amt, return_source, loss_flag, avg_spent
    FROM web_combined
) u
WHERE EXISTS (
    SELECT 1 FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = u.c_customer_sk
)
ORDER BY c_customer_id, return_source
