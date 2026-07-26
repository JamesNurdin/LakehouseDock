WITH combined_returns AS (
    SELECT 
        cr.cr_refunded_addr_sk AS address_sk,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt
    FROM catalog_returns cr
    UNION ALL
    SELECT 
        sr.sr_addr_sk AS address_sk,
        sr.sr_return_quantity AS return_qty,
        sr.sr_return_amt AS return_amt
    FROM store_returns sr
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    agg.total_return_qty,
    agg.avg_return_amt,
    CASE 
        WHEN agg.total_return_qty > 500 THEN 'VIP'
        WHEN agg.total_return_qty BETWEEN 200 AND 500 THEN 'PRO'
        ELSE 'REGULAR'
    END AS customer_tier,
    DENSE_RANK() OVER (ORDER BY agg.total_return_qty DESC) AS qty_rank
FROM (
    SELECT 
        address_sk,
        SUM(return_qty) AS total_return_qty,
        AVG(return_amt) AS avg_return_amt
    FROM combined_returns
    GROUP BY address_sk
) agg
JOIN customer_address ca ON agg.address_sk = ca.ca_address_sk
ORDER BY qty_rank
LIMIT 10
