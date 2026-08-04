WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
)
SELECT
    d.d_year,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_item_desc,
    regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT avg_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    regexp_like(i.i_item_desc, '[AEIOU].*')
    AND p.p_promo_name LIKE '%clearance%'
    AND EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
          AND sm.sm_type = 'AIR'
    )
GROUP BY
    d.d_year,
    c.c_first_name,
    c.c_last_name,
    i.i_item_desc,
    p.p_promo_name
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
