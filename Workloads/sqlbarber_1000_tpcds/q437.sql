SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    wr_sub.wr_return_amt AS related_wr_return_amt
FROM customer_demographics cd
JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT
        wr_refunded_cdemo_sk AS cd_demo_sk,
        MAX(wr_return_amt) AS wr_return_amt
    FROM web_returns
    WHERE wr_return_quantity = 36
    GROUP BY wr_refunded_cdemo_sk
) wr_sub
    ON wr_sub.cd_demo_sk = cd.cd_demo_sk
WHERE ss.ss_sold_date_sk = 2451831
  AND cr.cr_reason_sk = 44
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_demo_sk,
    wr_sub.wr_return_amt
HAVING SUM(cr.cr_return_amount) > 2822.70
