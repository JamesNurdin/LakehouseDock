SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_year AS return_year,
    d_closed.d_year AS store_closed_year,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txn_cnt,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_amt_inc_tax,
    SUM(sr.sr_net_loss) AS store_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_order_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_amt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    CASE
        WHEN SUM(cr.cr_return_amount) = 0 THEN NULL
        ELSE SUM(sr.sr_return_amt_inc_tax) / SUM(cr.cr_return_amount)
    END AS return_amount_ratio,
    AVG(
        CASE
            WHEN sr.sr_return_quantity = 0 THEN NULL
            ELSE CAST(cr.cr_return_quantity AS double) / sr.sr_return_quantity
        END
    ) AS avg_quantity_ratio,
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) AS total_net_loss,
    MAX(d_closed.d_date) AS store_closed_date
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
   AND cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_closed.d_year,
    r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
