WITH filtered_promos AS (
    SELECT
        p.p_promo_sk,
        CASE 
            WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 'Discount'
            WHEN regexp_like(p.p_promo_name, '(?i)clearance') THEN 'Clearance'
            ELSE 'Other'
        END AS promo_category
    FROM promotion p
    WHERE p.p_promo_name LIKE '%Sale%'
)
SELECT
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    fp.promo_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    CASE 
        WHEN SUM(ss.ss_net_profit) > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN filtered_promos fp
    ON ss.ss_promo_sk = fp.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND fp.promo_category = 'Discount'
GROUP BY
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state),
    fp.promo_category
ORDER BY total_net_profit DESC
LIMIT 100
