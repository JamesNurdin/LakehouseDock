WITH sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COUNT(*) AS num_sales,
    SUM(s.discount_amt) AS total_discount,
    AVG(s.discount_amt) AS avg_discount
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year = 2022
GROUP BY p.p_promo_id, p.p_promo_name
ORDER BY total_discount DESC
LIMIT 10
