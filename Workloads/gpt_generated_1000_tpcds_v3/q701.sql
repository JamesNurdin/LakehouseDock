WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_net_profit
    FROM catalog_sales
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_salutation,
    i.i_item_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS extracted_number,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT avg_net_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    SUBSTRING(c.c_email_address FROM 1 FOR 5) AS email_prefix,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '[A-Z]{2,}\\s[0-9]{2,}')
    AND c.c_email_address LIKE '%@example.com'
    AND EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 500
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    c.c_email_address,
    i.i_item_desc
ORDER BY total_net_profit DESC
LIMIT 50
