WITH promo_items AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_color,
           i.i_current_price,
           p.p_promo_id,
           p.p_purpose,
           p.p_discount_active
    FROM item i
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_purpose = 'Clearance'
      AND i.i_brand = 'Brand#45'
)
SELECT
    cc.cc_name,
    cc.cc_state,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    pi.p_promo_id,
    pi.p_purpose,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HighLoss'
        ELSE 'LowLoss'
    END AS loss_category
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN promo_items pi ON i.i_item_sk = pi.i_item_sk
JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
WHERE cc.cc_state = 'CA'
  AND ca.ca_country = 'United States'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_vehicle_count >= 2
  AND i.i_color IN ('Red', 'Blue')
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_channel_demo = 'N'
      )
GROUP BY
    cc.cc_name,
    cc.cc_state,
    ca.ca_city,
    cd.cd_gender,
    hd.hd_income_band_sk,
    pi.p_promo_id,
    pi.p_purpose
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
