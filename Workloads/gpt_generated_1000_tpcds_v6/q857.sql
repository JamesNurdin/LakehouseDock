WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_manufact,
        i_color,
        i_product_name,
        CASE
            WHEN regexp_like(i_manufact, '^bar') THEN 'Bar_Manufacturer'
            ELSE 'Other_Manufacturer'
        END AS manufact_category
    FROM item
    WHERE i_color LIKE 'p%'
      AND regexp_extract(i_product_name, '(\\d{4})', 1) IS NOT NULL
)
SELECT
    fi.manufact_category,
    substr(c.c_last_name, 1, 1) AS last_initial,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(CASE WHEN c.c_birth_month = 5 THEN 1 ELSE 0 END) AS may_birth_count
FROM filtered_items fi
JOIN store_returns sr
    ON sr.sr_item_sk = fi.i_item_sk
JOIN customer c
    ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = fi.i_item_sk
WHERE inv.inv_quantity_on_hand > 0
GROUP BY fi.manufact_category, substr(c.c_last_name, 1, 1)
ORDER BY total_return_amount DESC
LIMIT 100
