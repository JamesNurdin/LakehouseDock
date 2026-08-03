WITH distinct_promos AS (
        SELECT DISTINCT p_promo_sk, p_promo_name, p_item_sk, p_channel_dmail, p_discount_active, p_channel_event
        FROM promotion
    ),
    sales_base AS (
        SELECT cs.cs_sold_date_sk,
               cs.cs_ship_mode_sk,
               cs.cs_net_paid_inc_ship_tax,
               cs.cs_quantity,
               cs.cs_item_sk,
               cs.cs_promo_sk,
               cs.cs_catalog_page_sk,
               cs.cs_bill_cdemo_sk,
               cs.cs_ship_cdemo_sk
        FROM catalog_sales cs
        WHERE cs.cs_ship_mode_sk IN (1, 2, 6, 10, 15)
          AND cs.cs_net_paid_inc_ship_tax > 2000
          AND cs.cs_quantity >= 1
          AND cs.cs_sold_date_sk BETWEEN 2451937 AND 2452022
          AND cs.cs_ext_wholesale_cost < 4000
          AND cs.cs_ext_discount_amt > 0
    )
SELECT
    cp.cp_department,
    i.i_category,
    dp.p_promo_name,
    SUM(sb.cs_quantity) AS total_qty,
    SUM(sb.cs_net_paid_inc_ship_tax) AS total_sales,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(sb.cs_net_paid_inc_ship_tax) DESC) AS dept_sales_rank,
    lt.avg_item_price,
    (SELECT MAX(i2.i_current_price)
        FROM item i2
        WHERE i2.i_item_sk = sb.cs_item_sk) AS max_price_for_item
FROM sales_base sb
JOIN customer_demographics cd_bill
    ON sb.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN catalog_page cp
    ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON sb.cs_item_sk = i.i_item_sk
JOIN distinct_promos dp
    ON sb.cs_promo_sk = dp.p_promo_sk
LEFT JOIN LATERAL (
        SELECT AVG(cs2.cs_net_paid_inc_ship_tax) AS avg_item_price
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = sb.cs_item_sk
          AND cs2.cs_sold_date_sk = sb.cs_sold_date_sk
    ) lt ON true
WHERE cd_bill.cd_gender = 'M'
  AND cd_bill.cd_education_status = 'College'
  AND cp.cp_type = 'Traditional'
  AND i.i_size = 'large'
  AND dp.p_channel_dmail = 'Y'
  AND dp.p_discount_active = 'N'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_channel_event = 'N'
    )
GROUP BY cp.cp_department, i.i_category, dp.p_promo_name, lt.avg_item_price, sb.cs_item_sk
HAVING SUM(sb.cs_quantity) > 100
ORDER BY total_sales DESC
LIMIT 100
