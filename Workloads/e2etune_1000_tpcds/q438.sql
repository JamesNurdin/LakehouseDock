SELECT
    i.i_category,
    i.i_brand,
    p.p_channel_tv,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank_in_category
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    i.i_manager_id IN (6, 98, 18)
    AND i.i_color IN ('red', 'pink')
    AND p.p_discount_active = 'Y'
    AND p.p_response_target > 1000
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_channel_tv
HAVING
    SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 50
