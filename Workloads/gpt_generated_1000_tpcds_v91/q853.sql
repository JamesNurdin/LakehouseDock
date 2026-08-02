WITH combined_returns AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_returning_customer_sk AS returning_customer_sk,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        d_cr.d_year,
        d_cr.d_month_seq,
        d_cr.d_date,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss AS catalog_net_loss,
        r.r_reason_desc AS reason_desc,
        'catalog' AS return_type,
        cr.cr_order_number AS order_number,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.cr_store_credit
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        d_cr.d_year = 2020
        AND cr.cr_return_amount > 100
        AND cr.cr_store_credit < 500
        AND ca_ref.ca_state = 'CA'
        AND r.r_reason_desc IN ('Damaged', 'Defective')
),
web_combined AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_returning_customer_sk AS returning_customer_sk,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        d_wr.d_year,
        d_wr.d_month_seq,
        d_wr.d_date,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_net_loss AS web_net_loss,
        r.r_reason_desc AS reason_desc,
        'web' AS return_type,
        wr.wr_order_number AS order_number,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.web_name,
        ws.web_gmt_offset
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_wr.d_date_sk
    WHERE
        d_wr.d_year = 2020
        AND wr.wr_return_amt > 100
        AND wr.wr_return_ship_cost < 200
        AND ca_ref.ca_state = 'CA'
        AND r.r_reason_desc IN ('Damaged', 'Defective')
        AND ws.web_name = 'example.com'
)
SELECT
    COALESCE(cr.c_customer_id, wr.c_customer_id) AS customer_id,
    COALESCE(cr.c_first_name, wr.c_first_name) AS first_name,
    COALESCE(cr.c_last_name, wr.c_last_name) AS last_name,
    COALESCE(cr.d_year, wr.d_year) AS year,
    COALESCE(cr.d_month_seq, wr.d_month_seq) AS month_seq,
    SUM(COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT cr.order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.order_number) AS distinct_web_orders,
    CASE
        WHEN SUM(COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (
        PARTITION BY COALESCE(cr.d_year, wr.d_year)
        ORDER BY SUM(COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) DESC
    ) AS loss_rank,
    (
        SELECT AVG(monthly_loss) FROM (
            SELECT
                SUM(COALESCE(cr2.catalog_net_loss, 0) + COALESCE(wr2.web_net_loss, 0)) AS monthly_loss
            FROM combined_returns cr2
            LEFT JOIN web_combined wr2
                ON cr2.customer_sk = wr2.customer_sk
                AND cr2.d_month_seq = wr2.d_month_seq
            GROUP BY cr2.customer_sk, cr2.d_month_seq
        ) avg_sub
    ) AS avg_monthly_net_loss
FROM combined_returns cr
FULL OUTER JOIN web_combined wr
    ON cr.customer_sk = wr.customer_sk
    AND cr.d_month_seq = wr.d_month_seq
WHERE COALESCE(cr.d_year, wr.d_year) = 2020
GROUP BY
    COALESCE(cr.c_customer_id, wr.c_customer_id),
    COALESCE(cr.c_first_name, wr.c_first_name),
    COALESCE(cr.c_last_name, wr.c_last_name),
    COALESCE(cr.d_year, wr.d_year),
    COALESCE(cr.d_month_seq, wr.d_month_seq)
ORDER BY total_net_loss DESC
LIMIT 100
