WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_store_sk,
        ss.ss_net_profit,
        p.p_promo_name,
        c.c_email_address
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    fr.s_store_name,
    fr.s_store_sk,
    COUNT(*) AS sales_count,
    SUM(fr.ss_net_profit) AS total_net_profit,
    AVG(fr.ss_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(fr.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(fr.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    regexp_extract(fr.p_promo_name, '\\d+', 0) AS promo_number,
    CONCAT(fr.s_store_name, ' - ', 
        CASE
            WHEN SUM(fr.ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(fr.ss_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END) AS store_label,
    RANK() OVER (ORDER BY SUM(fr.ss_net_profit) DESC) AS profit_rank,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
FROM filtered_sales fr
GROUP BY fr.s_store_name, fr.s_store_sk, fr.p_promo_name
HAVING COUNT(*) >= 10
ORDER BY total_net_profit DESC
LIMIT 100
