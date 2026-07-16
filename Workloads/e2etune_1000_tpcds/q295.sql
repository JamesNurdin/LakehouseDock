SELECT
    dr.d_year,
    dr.d_moy,
    wp.wp_type,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_net_loss) AS total_net_loss,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim dc
    ON dr.d_year = dc.d_year
   AND dr.d_moy = dc.d_moy
JOIN web_page wp
    ON wp.wp_creation_date_sk = dc.d_date_sk
WHERE cr.cr_return_amount > 100
  AND cr.cr_net_loss > 0
  AND wp.wp_type IS NOT NULL
  AND wp.wp_image_count > 0
  AND dr.d_holiday = 'Y'
GROUP BY dr.d_year, dr.d_moy, wp.wp_type
HAVING SUM(cr.cr_return_amount) > 1000
   AND COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
