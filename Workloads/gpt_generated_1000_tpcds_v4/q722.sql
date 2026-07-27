WITH all_returns AS (
    SELECT
        cr_returned_date_sk      AS return_date_sk,
        cr_refunded_customer_sk  AS customer_sk,
        cr_reason_sk             AS reason_sk,
        cr_net_loss              AS net_loss,
        cr_return_quantity       AS qty,
        cr_return_amount         AS amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
    UNION ALL
    SELECT
        wr_returned_date_sk      AS return_date_sk,
        wr_refunded_customer_sk  AS customer_sk,
        wr_reason_sk             AS reason_sk,
        wr_net_loss              AS net_loss,
        wr_return_quantity       AS qty,
        wr_return_amt            AS amount
    FROM web_returns
    WHERE wr_return_amt > 0
)
SELECT
    r.r_reason_desc,
    regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS first_word,
    count(DISTINCT ar.customer_sk)               AS distinct_customers,
    sum(ar.net_loss)                             AS total_net_loss,
    concat(c.c_email_address, '-', regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1)) AS email_reason_tag
FROM all_returns ar
JOIN customer c ON ar.customer_sk = c.c_customer_sk
JOIN reason r   ON ar.reason_sk   = r.r_reason_sk
WHERE regexp_like(r.r_reason_desc, '(?i)did not')
  AND c.c_email_address LIKE '%@example.com'
GROUP BY r.r_reason_desc,
         regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1),
         c.c_email_address
HAVING count(DISTINCT ar.customer_sk) > 5
ORDER BY total_net_loss DESC
LIMIT 10
