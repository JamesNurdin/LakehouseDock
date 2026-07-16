SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    s.s_country,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(CASE WHEN i.i_color = 'Red' THEN 1 ELSE 0 END) AS red_item_returns
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, d.d_quarter_name, i.i_category, s.s_country
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_net_loss DESC
LIMIT 100
