/*
  Goal: Analyze store return performance for luxury‑style items (product names containing 'Deluxe' and a three‑digit code) that were part of Spring promotions, summarizing count, total and average net loss per brand, product code and return reason, and ranking brands by total loss.
*/
WITH returns_data AS (
    SELECT
        i.i_brand AS brand,
        i.i_product_name AS product_name,
        regexp_extract(i.i_product_name, '([0-9]{3})', 1) AS product_code,
        r.r_reason_desc AS reason_desc,
        sr.sr_net_loss AS net_loss,
        p.p_promo_name AS promo_name
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_product_name LIKE '%Deluxe%'
      AND regexp_like(i.i_product_name, '[0-9]{3}')
      AND (p.p_promo_name IS NULL OR regexp_like(p.p_promo_name, '^Spring.*'))
),
agg AS (
    SELECT
        brand,
        product_code,
        reason_desc,
        COUNT(*) AS return_cnt,
        SUM(net_loss) AS total_net_loss,
        AVG(net_loss) AS avg_net_loss
    FROM returns_data
    GROUP BY brand, product_code, reason_desc
)
SELECT
    brand,
    product_code,
    reason_desc,
    return_cnt,
    total_net_loss,
    avg_net_loss,
    ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_net_loss DESC) AS brand_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
