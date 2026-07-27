WITH sr AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_quantity > 0
)
SELECT
    s.s_store_name,
    r.r_reason_desc,
    d.d_year,
    COUNT(*) AS returns_count,
    SUM(sr.sr_return_quantity) AS total_quantity,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    MIN(sr.sr_return_amt) AS min_return_amount,
    MAX(sr.sr_return_amt) AS max_return_amount
FROM sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND r.r_reason_desc LIKE '%product%'
  AND s.s_company_name = 'Unknown'
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_date_sk = d.d_date_sk
          AND i.inv_item_sk = sr.sr_item_sk
          AND i.inv_quantity_on_hand > 0
    )
GROUP BY s.s_store_name, r.r_reason_desc, d.d_year
ORDER BY total_return_amount DESC
LIMIT 100
