WITH returns_by_ship_mode AS (
    SELECT
        cr.cr_ship_mode_sk,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_return_amount,
        MAX(cr.cr_returned_time_sk) AS max_returned_time_sk,
        MIN(cr.cr_returned_time_sk) AS min_returned_time_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_time_sk IN (45816, 74710, 71104, 28638, 44538)
      AND cr.cr_return_amount > 0
    GROUP BY cr.cr_ship_mode_sk
)
SELECT
    sm.sm_type,
    sm.sm_carrier,
    r.num_returns,
    r.total_return_amount,
    r.total_net_loss,
    r.avg_fee,
    r.high_value_return_amount,
    r.max_returned_time_sk,
    r.min_returned_time_sk,
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_type = 'product') AS total_product_pages,
    RANK() OVER (ORDER BY r.total_net_loss DESC) AS net_loss_rank
FROM returns_by_ship_mode r
JOIN ship_mode sm
  ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type IS NOT NULL
ORDER BY r.total_net_loss DESC
LIMIT 10
