WITH store_agg AS (
    SELECT sr_returned_date_sk,
           sum(sr_return_quantity) AS store_return_qty,
           sum(sr_return_amt)       AS store_return_amt,
           sum(sr_net_loss)        AS store_net_loss
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
web_agg AS (
    SELECT wr_returned_date_sk,
           sum(wr_return_quantity) AS web_return_qty,
           sum(wr_return_amt)       AS web_return_amt,
           sum(wr_net_loss)        AS web_net_loss
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT d.d_date,
       d.d_year,
       d.d_moy,
       coalesce(sa.store_return_qty, 0) AS store_return_qty,
       coalesce(wa.web_return_qty,   0) AS web_return_qty,
       coalesce(sa.store_return_amt, 0) AS store_return_amt,
       coalesce(wa.web_return_amt,   0) AS web_return_amt,
       coalesce(sa.store_net_loss,   0) AS store_net_loss,
       coalesce(wa.web_net_loss,    0) AS web_net_loss,
       coalesce(sa.store_net_loss, 0) + coalesce(wa.web_net_loss, 0) AS total_net_loss
FROM date_dim d
LEFT JOIN store_agg sa ON sa.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_agg   wa ON wa.wr_returned_date_sk = d.d_date_sk
WHERE d.d_date >= DATE '2022-01-01'
  AND d.d_date <  DATE '2023-01-01'
ORDER BY d.d_date
