WITH avg_warranty AS (
    SELECT avg(sr2.sr_net_loss) AS avg_loss
    FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    WHERE regexp_like(r2.r_reason_desc, '(?i)warranty')
)
SELECT
    concat(i.i_product_name, ' (', i.i_item_id, ')') AS product_label,
    i.i_item_desc,
    SUM(sr.sr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(sr.sr_net_loss) > (SELECT avg_loss FROM avg_warranty) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE regexp_like(r.r_reason_desc, '(?i)warranty')
  AND i.i_item_desc LIKE '%NEW%'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        JOIN reason r_ex ON sr_ex.sr_reason_sk = r_ex.r_reason_sk
        WHERE sr_ex.sr_item_sk = i.i_item_sk
          AND regexp_like(r_ex.r_reason_desc, '(?i)unauthorized')
  )
GROUP BY
    i.i_product_name,
    i.i_item_id,
    i.i_item_desc
ORDER BY total_net_loss DESC
LIMIT 100
