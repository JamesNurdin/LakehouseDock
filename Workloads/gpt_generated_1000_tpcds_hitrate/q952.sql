WITH web_agg AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_amt) AS web_return_sum
    FROM web_returns
    GROUP BY wr_reason_sk
),
union_data AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        r.r_reason_desc AS reason_desc,
        sr.sr_return_amt + 0.0 AS return_amt,
        sr.sr_net_loss AS net_loss,
        CASE WHEN sr.sr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        'store' AS source
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND s.s_number_employees > 50
      AND r.r_reason_id = 'AAAAAAAABAAAAAA'
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = sr.sr_ticket_number
          )
    UNION DISTINCT
    SELECT
        cr.cr_warehouse_sk AS store_sk,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amount + COALESCE(wa.web_return_sum, 0) AS return_amt,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_return_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_agg wa ON wa.wr_reason_sk = r.r_reason_sk
    WHERE w.w_state = 'CA'
      AND w.w_warehouse_sq_ft > 10000
      AND r.r_reason_desc LIKE '%damaged%'
      AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = cr.cr_order_number
          )
)
SELECT
    store_sk,
    reason_desc,
    qty_category,
    COUNT(*) AS cnt_returns,
    SUM(return_amt) AS total_return_amt,
    AVG(net_loss) AS avg_net_loss,
    MIN(net_loss) AS min_net_loss,
    MAX(net_loss) AS max_net_loss
FROM union_data
GROUP BY store_sk, reason_desc, qty_category
ORDER BY total_return_amt DESC
LIMIT 100
