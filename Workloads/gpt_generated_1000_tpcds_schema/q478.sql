WITH cte_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
) 
SELECT 
    i.i_item_id,
    i.i_product_name,
    cr.cr_return_amount,
    cs.cs_ext_sales_price,
    p.p_promo_name,
    r.r_reason_desc,
    cd.cd_gender,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.cr_return_amount DESC) AS rn_return_by_gender,
    LAG(cs.cs_ext_sales_price) OVER (PARTITION BY i.i_item_sk ORDER BY cs.cs_sold_date_sk) AS prev_sales_price,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
    ) AS total_store_return_amt
FROM store_returns sr
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_reason_sk = r.r_reason_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN cte_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
WHERE cd.cd_marital_status = 'S'
  AND i.i_brand = 'BrandX'
  AND cr.cr_return_amount > 100
  AND cs.cs_ext_tax > 50
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY cr.cr_return_amount DESC
LIMIT 100
