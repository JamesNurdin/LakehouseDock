WITH sales_returns AS (
    SELECT DISTINCT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_cdemo_sk,
        ss.ss_net_paid,
        cr.cr_return_amount,
        cr.cr_fee,
        d.d_year,
        cd.cd_credit_rating
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_credit_rating = 'Good'
      AND cr.cr_fee > 50
)
SELECT
    d_year,
    cd_credit_rating,
    SUM(ss_net_paid) AS total_sales_amount,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss_ticket_number) AS unique_sales_tickets,
    MIN(ss_net_paid) AS min_sale,
    MAX(ss_net_paid) AS max_sale
FROM sales_returns
GROUP BY d_year, cd_credit_rating
ORDER BY total_sales_amount DESC
LIMIT 100
