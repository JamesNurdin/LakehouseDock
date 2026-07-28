WITH reason_quarter AS (
    SELECT
        r.r_reason_desc,
        d.d_year,
        d.d_quarter_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 2
      AND r.r_reason_desc LIKE '%service%'
    GROUP BY r.r_reason_desc, d.d_year, d.d_quarter_seq
)
SELECT
    rq.r_reason_desc,
    rq.d_year,
    rq.d_quarter_seq,
    rq.total_net_loss,
    rq.return_cnt,
    rq.avg_return_amount,
    (SELECT MAX(inner_rq.avg_return_amount) FROM reason_quarter inner_rq) AS max_avg_return_amount_overall
FROM reason_quarter rq
WHERE rq.total_net_loss > (
    SELECT AVG(total_net_loss) FROM reason_quarter
)
ORDER BY rq.total_net_loss DESC
LIMIT 100
