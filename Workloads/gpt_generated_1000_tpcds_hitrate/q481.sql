WITH sr_join AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        cr.cr_return_amount,
        cp.cp_department,
        r.r_reason_desc,
        c.c_birth_year,
        ss.ss_net_profit,
        ss.ss_quantity,
        c.c_customer_id,
        ss.ss_sold_date_sk,
        cr.cr_catalog_page_sk
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE sr.sr_reason_sk = 11
      AND r.r_reason_desc LIKE '%color%'
      AND cp.cp_department = 'Electronics'
      AND c.c_birth_year BETWEEN 1970 AND 1980
      AND ss.ss_sold_date_sk = 2450595
      AND cr.cr_catalog_page_sk = 164
)
SELECT
    c.c_customer_id,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    lt.page_count
FROM sr_join sr
JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT cp2.cp_catalog_page_id) AS page_count
    FROM catalog_returns cr2
    JOIN catalog_page cp2
        ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
) lt
WHERE ss.ss_ticket_number IN (
    SELECT ss_ticket_number FROM store_sales
    EXCEPT
    SELECT sr_ticket_number FROM store_returns
)
GROUP BY c.c_customer_id, r.r_reason_desc, lt.page_count
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
