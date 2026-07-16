SELECT
    s.s_city,
    d.d_year,
    wp.wp_type,
    COUNT(DISTINCT cr.cr_order_number)               AS num_catalog_returns,
    COUNT(DISTINCT sr.sr_ticket_number)              AS num_store_returns,
    SUM(cr.cr_net_loss)                              AS total_catalog_net_loss,
    SUM(sr.sr_net_loss)                              AS total_store_net_loss,
    AVG(cr.cr_return_quantity)                       AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity)                       AS avg_store_return_qty,
    SUM(cr.cr_return_amount + sr.sr_return_amt)      AS total_return_amount,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN 1 ELSE 0 END) AS catalog_returns_with_tax,
    SUM(CASE WHEN sr.sr_return_tax > 0 THEN 1 ELSE 0 END) AS store_returns_with_tax
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_city,
    d.d_year,
    wp.wp_type
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_net_loss DESC
LIMIT 100
