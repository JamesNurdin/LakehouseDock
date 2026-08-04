WITH high_price_items AS (
    SELECT i_item_sk,
           i_category,
           i_current_price
    FROM   item
    WHERE  i_current_price > (
               SELECT MAX(i_current_price)
               FROM   item
               WHERE  i_category = 'Electronics'
           )
)
SELECT
    hd.hd_buy_potential,
    hp.i_category,
    t_sale.t_hour,
    SUM(ss.ss_net_profit)                         AS total_profit,
    SUM(sr.sr_return_amt)                         AS total_returns,
    COUNT(DISTINCT c.c_customer_sk)               AS customer_count,
    ARRAY_AGG(DISTINCT u.elem) FILTER (WHERE u.elem IS NOT NULL) AS keywords
FROM   store_sales ss
JOIN   time_dim t_sale ON ss.ss_sold_time_sk = t_sale.t_time_sk
JOIN   item i_sale ON ss.ss_item_sk = i_sale.i_item_sk
JOIN   high_price_items hp ON i_sale.i_item_sk = hp.i_item_sk
JOIN   customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN   household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN   income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN   time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN   item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
JOIN   web_page wp ON wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN UNNEST(split(i_sale.i_item_desc, ' ')) AS u(elem)
WHERE  c.c_customer_sk NOT IN (
           SELECT sr2.sr_customer_sk
           FROM   store_returns sr2
           WHERE  sr2.sr_return_amt > 1000
       )
GROUP BY
    hd.hd_buy_potential,
    hp.i_category,
    t_sale.t_hour
ORDER BY total_profit DESC
OFFSET 0 LIMIT 20
