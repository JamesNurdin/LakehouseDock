WITH all_returns AS (
    SELECT 
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_returned_date_sk      AS date_sk,
        cr.cr_net_loss             AS net_loss,
        cr.cr_return_quantity      AS return_qty,
        'catalog'                  AS return_type
    FROM catalog_returns cr
    UNION ALL
    SELECT 
        sr.sr_customer_sk AS customer_sk,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_net_loss        AS net_loss,
        sr.sr_return_quantity AS return_qty,
        'store'               AS return_type
    FROM store_returns sr
    UNION ALL
    SELECT 
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_returned_date_sk     AS date_sk,
        wr.wr_net_loss             AS net_loss,
        wr.wr_return_quantity      AS return_qty,
        'web'                      AS return_type
    FROM web_returns wr
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    SUM(ar.net_loss)                         AS total_net_loss,
    SUM(ar.return_qty)                       AS total_return_qty,
    COUNT(*)                                 AS total_returns,
    ROUND(SUM(ar.net_loss) / NULLIF(SUM(ar.return_qty), 0), 2) AS avg_loss_per_return
FROM all_returns ar
JOIN customer c
  ON ar.customer_sk = c.c_customer_sk
JOIN date_dim d
  ON ar.date_sk = d.d_date_sk
WHERE d.d_date >= DATE '1999-01-01'
  AND d.d_date < DATE '2002-01-01'
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
