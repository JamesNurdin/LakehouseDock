WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
promo_valid AS (
    SELECT p.p_promo_sk,
           p.p_promo_name
    FROM promotion p
    WHERE p.p_promo_sk IN (
        SELECT p1.p_promo_sk FROM promotion p1 WHERE p1.p_channel_tv = 'N'
        EXCEPT
        SELECT p2.p_promo_sk FROM promotion p2 WHERE p2.p_discount_active = 'Y'
    )
),
call_center_ca AS (
    SELECT *
    FROM call_center
    WHERE cc_state = 'CA'
      AND cc_market_manager LIKE '%John%'
      AND cc_gmt_offset > -5
),
call_center_tx AS (
    SELECT *
    FROM call_center
    WHERE cc_state = 'TX'
      AND cc_market_manager LIKE '%Smith%'
      AND cc_employees > 50
),
catalog_page_monthly AS (
    SELECT *
    FROM catalog_page
    WHERE cp_type = 'monthly'
),
catalog_page_electronics AS (
    SELECT *
    FROM catalog_page
    WHERE cp_department = 'Electronics'
)
SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    s.cs_net_profit,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY s.cs_net_profit DESC) AS rn
FROM sampled_sales s
JOIN call_center_ca cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page_monthly cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promo_valid p ON s.cs_promo_sk = p.p_promo_sk
WHERE s.cs_net_profit > 0
  AND s.cs_ext_ship_cost > (
        SELECT AVG(cs_ext_ship_cost) FROM catalog_sales
    )
  AND s.cs_quantity > 5
  AND s.cs_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM catalog_page_electronics)
  AND s.cs_call_center_sk IN (
        SELECT cc_call_center_sk FROM call_center WHERE cc_company_name IS NOT NULL
    )

UNION DISTINCT

SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    s.cs_net_profit,
    DENSE_RANK() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY s.cs_net_profit DESC) AS rn
FROM sampled_sales s
JOIN call_center_tx cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page_monthly cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promo_valid p ON s.cs_promo_sk = p.p_promo_sk
WHERE s.cs_net_profit > 0
  AND s.cs_ext_ship_cost > (
        SELECT AVG(cs_ext_ship_cost) FROM catalog_sales
    )
  AND s.cs_quantity > 10
  AND s.cs_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM catalog_page_electronics)
  AND s.cs_call_center_sk IN (
        SELECT cc_call_center_sk FROM call_center WHERE cc_company_name IS NOT NULL
    )

ORDER BY cs_net_profit DESC
LIMIT 100
