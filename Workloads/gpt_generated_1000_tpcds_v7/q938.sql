WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        i.i_item_desc,
        c.c_email_address,
        w.w_city,
        w.w_warehouse_name
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{2,}\\b')
      AND c.c_email_address LIKE '%@example.com'
      AND ss.ss_promo_sk BETWEEN 800 AND 900
)
SELECT
    w_city,
    w_warehouse_name,
    regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word,
    concat('WH_', w_city) AS warehouse_label,
    COUNT(*) AS sales_transactions,
    SUM(ss_net_profit) AS total_net_profit,
    ROUND(AVG(ss_net_profit), 2) AS avg_net_profit
FROM filtered_sales
GROUP BY
    w_city,
    w_warehouse_name,
    regexp_extract(i_item_desc, '(\\w+)', 1),
    concat('WH_', w_city)
ORDER BY total_net_profit DESC
LIMIT 20
