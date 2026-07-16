SELECT
    d.d_year,
    s.s_store_id,
    s.s_city,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(DISTINCT wp.wp_url) AS distinct_pages,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_return_amount,
    SUM(ss.ss_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales_minus_returns,
    SUM(ss.ss_net_paid) / NULLIF(SUM(ss.ss_quantity), 0) AS avg_paid_per_quantity,
    CASE WHEN SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) > 0 THEN 'Positive' ELSE 'Negative' END AS overall_contribution
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_store_sk = s.s_store_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    s.s_store_id,
    s.s_city,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY d.d_year DESC, total_net_profit DESC
LIMIT 100
