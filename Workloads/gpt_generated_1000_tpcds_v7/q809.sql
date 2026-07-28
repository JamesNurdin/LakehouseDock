/*
Goal: Calculate total net profit and number of sales for each promotion (identified by a concatenated promo_id‑promo_sk key) where the promotion name matches a specific pattern, the promotion is active, and the channel details start with 'Email'. The query extracts the primary TV or Radio channel from the channel details, limits analysis to recent sales (last 30 surrogate‑date units) with coupon amounts above 200, and aggregates the results.
*/
WITH recent_sales AS (
    SELECT cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk > (
        SELECT max(cs2.cs_sold_date_sk) - 30
        FROM catalog_sales cs2
    )
      AND cs.cs_coupon_amt > 200
    GROUP BY cs.cs_promo_sk
)
SELECT
    concat(p.p_promo_id, '-', cast(p.p_promo_sk as varchar)) AS promo_key,
    regexp_extract(p.p_channel_details, '(TV|Radio)', 1) AS primary_channel,
    sum(cs.cs_net_profit) AS total_net_profit,
    count(*) AS sale_count
FROM catalog_sales cs
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    regexp_like(p.p_promo_name, '^Promo[0-9]{3}$')
    AND p.p_discount_active = 'Y'
    AND p.p_channel_details LIKE 'Email%'
    AND cs.cs_ext_tax > 50
    AND cs.cs_promo_sk IN (SELECT cs_promo_sk FROM recent_sales)
GROUP BY
    concat(p.p_promo_id, '-', cast(p.p_promo_sk as varchar)),
    regexp_extract(p.p_channel_details, '(TV|Radio)', 1)
ORDER BY total_net_profit DESC
LIMIT 20
