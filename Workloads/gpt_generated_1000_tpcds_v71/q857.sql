WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_suite_number LIKE 'Suite %'
      AND regexp_like(ca.ca_suite_number, '^Suite [A-Z]$')
      AND ca.ca_city LIKE '%Oak%'
)
SELECT
    ca.ca_city,
    hd.hd_buy_potential,
    COUNT(DISTINCT fr.cr_order_number) AS num_orders,
    SUM(fr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    regexp_extract(ca.ca_suite_number, 'Suite (.)', 1) AS suite_letter,
    concat(ca.ca_city, '-', hd.hd_buy_potential) AS city_buy_potential_key
FROM filtered_returns fr
JOIN catalog_sales cs
    ON fr.cr_order_number = cs.cs_order_number
   AND fr.cr_item_sk = cs.cs_item_sk
JOIN customer_address ca
    ON fr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_net_profit > 0
GROUP BY
    ca.ca_city,
    hd.hd_buy_potential,
    ca.ca_suite_number,
    concat(ca.ca_city, '-', hd.hd_buy_potential)
HAVING SUM(fr.cr_net_loss) > (
    SELECT AVG(cr2.cr_net_loss) * 1.5
    FROM catalog_returns cr2
)
ORDER BY total_return_loss DESC
LIMIT 100
