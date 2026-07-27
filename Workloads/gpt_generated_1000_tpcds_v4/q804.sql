WITH sales_by_promo AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_channel_catalog AS channel_catalog,
        p.p_channel_event AS channel_event,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_coupon_amt) AS total_coupons,
        COUNT(*) AS transaction_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE cd.cd_purchase_estimate > 2000
      AND cd.cd_marital_status = 'M'
      AND p.p_channel_catalog = 'N'
      AND p.p_discount_active = 'Y'
      AND ss.ss_ext_sales_price > 500
    GROUP BY p.p_promo_id, p.p_channel_catalog, p.p_channel_event, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_ext_sales_price) > 10000
       AND COUNT(*) >= 10
)
SELECT
    promo_id,
    channel_catalog,
    channel_event,
    gender,
    marital_status,
    total_sales,
    total_coupons,
    transaction_cnt,
    avg_discount
FROM sales_by_promo
ORDER BY total_sales DESC
LIMIT 100
