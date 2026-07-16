WITH sales_and_returns AS (
    SELECT
        d_sold.d_date,
        d_sold.d_year,
        s.s_store_id,
        s.s_state,
        r.r_reason_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM
        store_sales ss
    JOIN
        date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN
        store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN
        date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN
        catalog_returns cr
        ON cr.cr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN
        reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        d_sold.d_year = 2022
        AND s.s_state = 'CA'
    GROUP BY
        d_sold.d_date,
        d_sold.d_year,
        s.s_store_id,
        s.s_state,
        r.r_reason_desc
)
SELECT
    d_date,
    d_year,
    s_store_id,
    s_state,
    r_reason_desc,
    total_sales,
    total_profit,
    num_tickets,
    total_return_qty,
    total_return_amount,
    total_return_loss,
    (total_sales - COALESCE(total_return_amount, 0)) AS net_sales_after_returns,
    CASE
        WHEN total_sales > 0 THEN (COALESCE(total_return_amount, 0) / total_sales) * 100
        ELSE NULL
    END AS return_rate_percent,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY d_date DESC) AS rn
FROM
    sales_and_returns
ORDER BY
    total_sales DESC
LIMIT 100
