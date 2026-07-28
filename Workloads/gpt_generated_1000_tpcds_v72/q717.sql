WITH return_agg AS (
    SELECT
        cr_order_number,
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_tax) AS total_return_tax
    FROM catalog_returns
    WHERE cr_return_tax > 30.00
      AND cr_store_credit < 500.00
      AND cr_fee BETWEEN 5.00 AND 100.00
    GROUP BY cr_order_number, cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(return_agg.total_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN return_agg
    ON cs.cs_order_number = return_agg.cr_order_number
   AND cs.cs_item_sk = return_agg.cr_item_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cs.cs_sold_date_sk BETWEEN 2451010 AND 2451015
  AND i.i_current_price > 30.00
  AND p.p_discount_active = 'Y'
  AND cd.cd_credit_rating = 'High Risk'
  AND hd.hd_income_band_sk = 5
  AND cs.cs_coupon_amt < 500.00
GROUP BY
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cd.cd_credit_rating,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
