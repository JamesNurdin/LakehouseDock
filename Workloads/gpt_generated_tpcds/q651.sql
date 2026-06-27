SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_date >= DATE '2001-01-01'
  AND d.d_date < DATE '2002-01-01'
GROUP BY s.s_store_name, d.d_year, d.d_month_seq, p.p_promo_name
ORDER BY total_sales_amount DESC
LIMIT 100
