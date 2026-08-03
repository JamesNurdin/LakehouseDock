WITH sales_agg AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        MIN(cs.cs_bill_cdemo_sk) AS bill_cdemo_sk,
        MIN(cs.cs_bill_hdemo_sk) AS bill_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY cs.cs_promo_sk, cs.cs_catalog_page_sk
)
SELECT
    cp.cp_catalog_number,
    cp.cp_department,
    p.p_promo_name,
    p.p_channel_radio,
    hd.hd_vehicle_count,
    cd.cd_gender,
    sa.total_sales,
    sa.total_quantity,
    sa.order_cnt,
    (
        SELECT COUNT(*) FROM (
            SELECT cs.cs_order_number
            FROM catalog_sales cs
            JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
            WHERE p2.p_channel_tv = 'Y'
            EXCEPT
            SELECT cs.cs_order_number
            FROM catalog_sales cs
            JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
            WHERE p2.p_channel_radio = 'N'
        ) diff_orders
    ) AS tv_not_radio_order_cnt
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = sa.bill_cdemo_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = sa.bill_hdemo_sk
WHERE cp.cp_catalog_number IN (10, 14)
  AND hd.hd_vehicle_count >= 2
  AND p.p_channel_radio = 'N'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1 FROM promotion p3
        WHERE p3.p_promo_sk = p.p_promo_sk
          AND p3.p_discount_active = 'Y'
    )
ORDER BY sa.total_sales DESC
OFFSET 0 LIMIT 100
