WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        i.i_item_desc,
        p.p_promo_name,
        ss.ss_net_paid,
        ss.ss_quantity,
        regexp_extract(i.i_item_desc, '(Red|Blue|Green)', 1) AS extracted_color,
        CASE
            WHEN ss.ss_net_paid > 1000 THEN 'High'
            WHEN ss.ss_net_paid BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_bucket
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\bBlue\\b')
      AND p.p_promo_name LIKE '%Clearance%'
)
SELECT
    p.p_promo_name,
    COUNT(DISTINCT fs.ss_ticket_number) AS num_transactions,
    SUM(fs.ss_net_paid) AS total_net_paid,
    SUM(CASE WHEN fs.sales_bucket = 'High' THEN fs.ss_net_paid ELSE 0 END) AS high_sales_amount,
    AVG(fs.ss_quantity) AS avg_quantity,
    MAX(fs.extracted_color) AS extracted_color,
    CONCAT('Promo-', CAST(fs.ss_promo_sk AS VARCHAR)) AS promo_key
FROM filtered_sales fs
JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = fs.ss_item_sk
      AND sr.sr_ticket_number = fs.ss_ticket_number
)
GROUP BY p.p_promo_name, fs.ss_promo_sk
ORDER BY total_net_paid DESC
LIMIT 10
