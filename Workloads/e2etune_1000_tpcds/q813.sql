SELECT
    s.s_store_name,
    i.i_class,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount_total,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_txn_count
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
GROUP BY s.s_store_name, i.i_class
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY net_profit DESC
LIMIT 100
