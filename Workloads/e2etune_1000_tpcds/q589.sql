WITH sales_with_promos AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2459200 AND 2459565
      AND (p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y')
)
SELECT
    s.s_state AS store_state,
    ca.ca_state AS customer_state,
    i.i_brand,
    SUM(swp.ss_quantity) AS total_quantity,
    SUM(swp.ss_net_profit) AS total_net_profit,
    AVG(swp.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT swp.ss_promo_sk) AS promo_count,
    COUNT(DISTINCT swp.ss_ticket_number) AS distinct_tickets
FROM sales_with_promos swp
JOIN store s ON swp.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON swp.ss_addr_sk = ca.ca_address_sk
JOIN item i ON swp.ss_item_sk = i.i_item_sk
GROUP BY s.s_state, ca.ca_state, i.i_brand
HAVING SUM(swp.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 20
