/*
Goal: Analyze the profitability and return impact of items in category 5 sold in Dozen units, focusing on promotions with moderate cost, and identify the most profitable promotion‑item combinations while filtering for significant returns and sales.
*/
SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(cr.cr_return_ship_cost) AS max_return_ship_cost
FROM
    catalog_returns cr
JOIN
    item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN
    promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN
    store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_promo_sk = p.p_promo_sk
WHERE
    i.i_category_id = 5
    AND i.i_units = 'Dozen'
    AND cr.cr_store_credit > 0.15
    AND ss.ss_ext_wholesale_cost > 1500
    AND p.p_cost < 5000
GROUP BY
    i.i_category,
    i.i_brand,
    p.p_promo_name
ORDER BY
    total_net_profit DESC
LIMIT 100
