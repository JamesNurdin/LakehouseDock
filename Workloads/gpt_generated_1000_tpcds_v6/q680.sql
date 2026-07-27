WITH sales_with_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_tax,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cr.cr_return_amount
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cs.cs_ext_tax > 30
      AND cs.cs_warehouse_sk IN (1, 15)
)
SELECT
    cp.cp_department,
    sm.sm_type,
    cd.cd_gender,
    COUNT(DISTINCT swr.cs_order_number) AS order_cnt,
    SUM(swr.cs_net_paid) AS total_net_paid,
    AVG(swr.cs_ext_tax) AS avg_ext_tax,
    SUM(CASE WHEN swr.cs_net_paid > 5000 THEN 1 ELSE 0 END) AS high_value_orders,
    SUM(COALESCE(swr.cr_return_amount, 0)) AS total_return_amount,
    CASE WHEN SUM(swr.cs_net_paid) > 100000 THEN 'BIG' ELSE 'SMALL' END AS sales_volume_category
FROM sales_with_returns swr
JOIN catalog_page cp
    ON swr.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON swr.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON swr.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
    ON swr.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE sm.sm_code = 'AIR'
  AND p.p_channel_radio = 'N'
GROUP BY cp.cp_department, sm.sm_type, cd.cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
