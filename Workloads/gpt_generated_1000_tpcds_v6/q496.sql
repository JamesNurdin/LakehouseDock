WITH reason_cte AS (
    SELECT r_reason_sk,
           r_reason_id,
           r_reason_desc
    FROM reason
),
max_loss_cte AS (
    SELECT MAX(cr_net_loss) AS max_cr_loss
    FROM catalog_returns
)
SELECT
    r.r_reason_desc AS reason,
    SUM(u.net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    CASE
        WHEN SUM(u.net_loss) > (SELECT max_cr_loss FROM max_loss_cte) THEN 'Above Max Catalog Loss'
        ELSE 'Within Catalog Loss'
    END AS loss_category
FROM (
    SELECT cr.cr_reason_sk AS reason_sk,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
    UNION ALL
    SELECT wr.wr_reason_sk AS reason_sk,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_qty
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_max_ad_count >= 1
) u
JOIN reason_cte r ON u.reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc
HAVING SUM(u.net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
