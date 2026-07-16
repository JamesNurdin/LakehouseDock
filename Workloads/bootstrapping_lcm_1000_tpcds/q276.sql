SELECT
    s.s_store_name,
    (d.d_year * 100 + d.d_moy) AS year_month,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_city AS returning_city,
    ca_sr.ca_city AS store_return_city,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    CASE WHEN SUM(cr.cr_net_loss) <> 0 THEN SUM(sr.sr_net_loss) / SUM(cr.cr_net_loss) ELSE NULL END AS loss_ratio,
    SUM(cr.cr_return_quantity) - SUM(sr.sr_return_quantity) AS net_return_qty_diff
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s2
    ON sr.sr_store_sk = s2.s_store_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
  AND s2.s_state = 'CA'
GROUP BY
    s.s_store_name,
    (d.d_year * 100 + d.d_moy),
    ca_refunded.ca_state,
    ca_returning.ca_city,
    ca_sr.ca_city
HAVING COUNT(*) > 10
ORDER BY total_catalog_net_loss DESC
LIMIT 100
