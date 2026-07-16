WITH returns_by_date AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_fee,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
)
SELECT
    d.d_year,
    s.s_state,
    w.web_state,
    p.p_channel_tv,
    SUM(r.cr_return_amount) AS total_return_amount,
    SUM(r.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT r.cr_order_number) AS distinct_orders,
    AVG(r.cr_fee) AS avg_fee,
    MAX(r.cr_return_quantity) AS max_return_qty,
    COUNT(*) AS return_rows,
    CASE
        WHEN SUM(r.cr_net_loss) > 1000 THEN 'HIGH'
        WHEN SUM(r.cr_net_loss) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category
FROM returns_by_date r
JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND p.p_discount_active = 'Y'
  AND d.d_date_sk <= p.p_end_date_sk
GROUP BY
    d.d_year,
    s.s_state,
    w.web_state,
    p.p_channel_tv
HAVING SUM(r.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
