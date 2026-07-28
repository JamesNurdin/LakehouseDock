WITH reason_returns AS (
    SELECT
        r.r_reason_desc,
        r.r_reason_id,
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_catalog_page_sk IN (264, 201, 214, 256, 66)
      AND cr.cr_refunded_addr_sk BETWEEN 500000 AND 6000000
      AND cr.cr_returning_addr_sk NOT IN (585197, 4421968)
      AND r.r_reason_id IN (
          'AAAAAAAAABAAAAAA',
          'AAAAAAAAGAAAAAAA',
          'AAAAAAAANAAAAAAA',
          'AAAAAAAADAAAAAAA')
      AND cr.cr_return_quantity > 1
      AND cr.cr_returned_date_sk >= 2450000
    GROUP BY r.r_reason_desc, r.r_reason_id, cr.cr_returned_date_sk
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    rr.r_reason_desc,
    rr.r_reason_id,
    rr.cr_returned_date_sk,
    rr.total_return_amount,
    rr.total_net_loss,
    rr.return_cnt,
    rr.avg_quantity,
    SUM(rr.total_return_amount) OVER (PARTITION BY rr.r_reason_desc) AS sum_amount_by_reason,
    RANK() OVER (ORDER BY rr.total_return_amount DESC) AS amount_rank
FROM reason_returns rr
WHERE rr.return_cnt >= 5
ORDER BY rr.total_return_amount DESC
LIMIT 100
