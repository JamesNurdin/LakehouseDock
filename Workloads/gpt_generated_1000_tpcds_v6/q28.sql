WITH high_sales AS (
    SELECT
        promotion.p_promo_name AS promo_name,
        web_site.web_name AS site_name,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT web_sales.ws_order_number) AS order_cnt
    FROM web_sales
    JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk
    WHERE promotion.p_discount_active = 'Y'
      AND customer_demographics.cd_purchase_estimate >= 7000
    GROUP BY promotion.p_promo_name, web_site.web_name
),
low_sales AS (
    SELECT
        promotion.p_promo_name AS promo_name,
        web_site.web_name AS site_name,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT web_sales.ws_order_number) AS order_cnt
    FROM web_sales
    JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk
    WHERE promotion.p_discount_active = 'N'
      AND customer_demographics.cd_purchase_estimate < 5000
    GROUP BY promotion.p_promo_name, web_site.web_name
)
SELECT
    promo_name,
    site_name,
    total_sales,
    order_cnt
FROM (
    SELECT promo_name, site_name, total_sales, order_cnt FROM high_sales
    UNION ALL
    SELECT promo_name, site_name, total_sales, order_cnt FROM low_sales
) AS combined
ORDER BY total_sales DESC
LIMIT 100
