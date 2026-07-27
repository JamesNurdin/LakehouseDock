WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450905 AND 2450995
      AND cs.cs_quantity > 0
)
SELECT
    c.c_customer_id,
    i.i_category,
    sm.sm_type,
    cp.cp_catalog_page_number,
    p.p_promo_name,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    SUM(fs.cs_net_paid) AS total_net_paid,
    SUM(CASE WHEN fs.cs_net_profit > 0 THEN fs.cs_net_paid ELSE 0 END) AS profit_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    (
        SELECT SUM(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk BETWEEN 2450905 AND 2450995
    ) AS overall_net_paid,
    CASE
        WHEN SUM(fs.cs_net_paid) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_volume_category
FROM filtered_sales fs
JOIN customer c
    ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON fs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = fs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
WHERE cp.cp_catalog_page_number IN (7, 14)
  AND p.p_channel_email = 'N'
  AND i.i_brand = 'BrandA'
  AND sr.sr_return_quantity > 2
  AND (cr.cr_fee IS NULL OR cr.cr_fee > 20)
GROUP BY GROUPING SETS (
    (c.c_customer_id, i.i_category, sm.sm_type, cp.cp_catalog_page_number, p.p_promo_name),
    (c.c_customer_id, i.i_category, sm.sm_type, cp.cp_catalog_page_number),
    (c.c_customer_id, i.i_category),
    (c.c_customer_id),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
