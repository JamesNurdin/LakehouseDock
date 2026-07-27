WITH sales_agg AS (
    SELECT
        cs_promo_sk,
        cs_item_sk,
        SUM(cs_net_paid) AS sum_net_paid,
        SUM(cs_quantity) AS sum_quantity,
        AVG(cs_ext_discount_amt) AS avg_discount,
        MIN(cs_ext_tax) AS min_tax,
        MAX(cs_ext_list_price) AS max_list_price
    FROM catalog_sales
    WHERE cs_ext_list_price > 5000
      AND cs_ship_date_sk BETWEEN 2450840 AND 2450900
      AND cs_quantity >= 2
      AND cs_net_paid_inc_tax < 20000
      AND cs_ext_tax > 20
    GROUP BY cs_promo_sk, cs_item_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    COUNT(*) AS promo_item_count,
    SUM(s.sum_net_paid) AS total_net_paid,
    SUM(s.sum_quantity) AS total_quantity,
    AVG(s.avg_discount) AS overall_avg_discount,
    MIN(s.min_tax) AS overall_min_tax,
    MAX(s.max_list_price) AS overall_max_list_price
FROM sales_agg s
JOIN promotion p
  ON s.cs_promo_sk = p.p_promo_sk
WHERE p.p_channel_email = 'N'
  AND p.p_channel_radio = 'N'
  AND p.p_promo_name LIKE '%Summer%'
  AND p.p_start_date_sk >= 2450800
  AND p.p_end_date_sk <= 2450950
GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_email
ORDER BY total_net_paid DESC
LIMIT 100
