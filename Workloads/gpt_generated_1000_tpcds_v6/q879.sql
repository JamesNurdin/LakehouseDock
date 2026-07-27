WITH avg_price AS (
    SELECT AVG(ss_sales_price) AS overall_avg_price
    FROM tpcds.store_sales
)
SELECT
    s.s_store_id,
    s.s_city,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    CASE
        WHEN AVG(ss.ss_sales_price) > (SELECT overall_avg_price FROM avg_price) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS price_category,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM tpcds.store_sales ss
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN tpcds.catalog_sales cs
    ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    s.s_market_desc LIKE '%financial%'
    AND s.s_street_number IN ('337', '226')
    AND s.s_company_name = 'Unknown'
    AND p.p_discount_active = 'N'
    AND ss.ss_sales_price BETWEEN 1.00 AND 50.00
    AND cs.cs_quantity > 1
GROUP BY
    s.s_store_id,
    s.s_city,
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
