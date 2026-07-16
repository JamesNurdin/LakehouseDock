SELECT
    s.s_store_id,
    s.s_city,
    p.p_promo_name,
    d.d_year,
    CASE WHEN d.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(cr.cr_return_quantity) AS total_return_qty,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_qty_sales,
    SUM(CASE WHEN ss.ss_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS discount_txns
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_start_date_sk = d.d_date_sk
    AND p.p_end_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND ss.ss_quantity > 0
GROUP BY
    s.s_store_id,
    s.s_city,
    p.p_promo_name,
    d.d_year,
    CASE WHEN d.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
