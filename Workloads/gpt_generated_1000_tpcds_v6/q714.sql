WITH distinct_promos AS (
    SELECT DISTINCT p_promo_sk,
                    p_promo_name,
                    p_channel_catalog
    FROM promotion
    WHERE p_channel_catalog = 'Y'
)
SELECT
    dp.p_promo_name,
    i.i_brand,
    d.d_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    CASE
        WHEN SUM(ss.ss_net_profit) > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS relative_profit,
    CONCAT(i.i_brand, '-', dp.p_promo_name) AS brand_promo,
    AVG(CAST(regexp_extract(i.i_item_desc, '(\\d+)', 1) AS INTEGER)) AS avg_desc_number
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN distinct_promos dp ON ss.ss_promo_sk = dp.p_promo_sk
WHERE regexp_like(i.i_item_desc, '^\\d{3}')
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ss.ss_item_sk
          AND sr.sr_ticket_number = ss.ss_ticket_number
    )
GROUP BY dp.p_promo_name, i.i_brand, d.d_year
HAVING SUM(ss.ss_net_profit) > 50000
ORDER BY total_net_profit DESC
LIMIT 100
