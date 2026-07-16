WITH date_returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         SUM(cr.cr_net_loss) AS date_net_loss,
         COUNT(*) AS date_return_cnt
  FROM catalog_returns cr
  GROUP BY cr.cr_returned_date_sk
),
page_returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         wp.wp_type AS wp_type,
         COUNT(*) AS returns_cnt,
         SUM(cr.cr_net_loss) AS net_loss,
         AVG(cr.cr_return_quantity) AS avg_qty,
         SUM(CASE WHEN cr.cr_ship_mode_sk = 2 THEN cr.cr_return_amount ELSE 0 END) AS ship_mode_2_amount
  FROM catalog_returns cr
  JOIN web_page wp
    ON cr.cr_returned_date_sk = wp.wp_access_date_sk
  WHERE cr.cr_net_loss > 50
    AND wp.wp_type IS NOT NULL
  GROUP BY cr.cr_returned_date_sk, wp.wp_type
)
SELECT pr.date_sk,
       pr.wp_type,
       pr.returns_cnt,
       pr.net_loss,
       pr.avg_qty,
       pr.ship_mode_2_amount,
       RANK() OVER (PARTITION BY pr.date_sk ORDER BY pr.net_loss DESC) AS net_loss_rank,
       dr.date_return_cnt,
       dr.date_net_loss
FROM page_returns pr
JOIN date_returns dr
  ON pr.date_sk = dr.date_sk
WHERE pr.returns_cnt > 5
ORDER BY pr.net_loss DESC
LIMIT 100
