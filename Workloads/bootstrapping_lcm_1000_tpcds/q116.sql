SELECT
    rank,
    store_id,
    store_name,
    year,
    month_seq,
    reason_desc,
    num_tickets,
    total_sales,
    total_return_amount,
    net_sales_minus_returns
FROM (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ss.ss_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales_minus_returns,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) - SUM(cr.cr_return_amount) DESC) AS rank
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc
) t
ORDER BY rank
LIMIT 100
