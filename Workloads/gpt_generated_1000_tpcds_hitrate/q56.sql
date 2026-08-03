WITH sales_subset AS (
    SELECT DISTINCT
        ss.ss_item_sk   AS item_sk,
        ss.ss_store_sk AS store_sk
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE cd.cd_purchase_estimate > 3000
      AND p.p_channel_email = 'Y'
),
returns_subset AS (
    SELECT DISTINCT
        sr.sr_item_sk   AS item_sk,
        sr.sr_store_sk AS store_sk
    FROM store_returns sr
    JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cd2.cd_dep_employed_count >= 2
      AND r.r_reason_desc LIKE '%damage%'
)
SELECT item_sk, store_sk
FROM sales_subset
INTERSECT
SELECT item_sk, store_sk
FROM returns_subset
ORDER BY item_sk, store_sk
LIMIT 100
