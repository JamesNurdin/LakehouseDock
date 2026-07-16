WITH cat_agg AS (
    SELECT
        cs.cs_promo_sk,
        COUNT(*) AS cat_sales_cnt,
        SUM(cs.cs_net_paid_inc_tax) AS cat_total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS cat_total_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS cat_unique_customers
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND p.p_discount_active = 'Y'
    GROUP BY cs.cs_promo_sk
),
web_agg AS (
    SELECT
        ws.ws_promo_sk,
        COUNT(*) AS web_sales_cnt,
        SUM(ws.ws_net_paid_inc_tax) AS web_total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS web_total_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_unique_customers
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'product'
    GROUP BY ws.ws_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(cat.cat_sales_cnt, 0) AS catalog_sales_count,
    COALESCE(web.web_sales_cnt, 0) AS web_sales_count,
    COALESCE(cat.cat_total_net_paid, 0) + COALESCE(web.web_total_net_paid, 0) AS total_net_paid,
    COALESCE(cat.cat_total_discount, 0) + COALESCE(web.web_total_discount, 0) AS total_discount,
    (COALESCE(cat.cat_total_discount, 0) + COALESCE(web.web_total_discount, 0)) /
        NULLIF(COALESCE(cat.cat_sales_cnt, 0) + COALESCE(web.web_sales_cnt, 0), 0) AS avg_discount_per_sale,
    COALESCE(cat.cat_unique_customers, 0) + COALESCE(web.web_unique_customers, 0) AS total_unique_customers,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cat.cat_total_net_paid, 0) + COALESCE(web.web_total_net_paid, 0) DESC) AS promo_rank
FROM promotion p
LEFT JOIN cat_agg cat ON p.p_promo_sk = cat.cs_promo_sk
LEFT JOIN web_agg web ON p.p_promo_sk = web.ws_promo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_start_date_sk >= 2450800
  AND p.p_end_date_sk <= 2450900
  AND (COALESCE(cat.cat_total_net_paid, 0) + COALESCE(web.web_total_net_paid, 0)) > 10000
ORDER BY total_net_paid DESC
LIMIT 50
