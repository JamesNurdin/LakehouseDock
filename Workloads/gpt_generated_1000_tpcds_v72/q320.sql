WITH cr_filtered AS (
    SELECT cr.*
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
)
SELECT
    cp.cp_department,
    i_store.i_brand,
    p.p_promo_name,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(p.p_cost) AS avg_promo_cost
FROM store_returns sr
JOIN item i_store
    ON sr.sr_item_sk = i_store.i_item_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_cust
    ON sr.sr_cdemo_sk = cd_cust.cd_demo_sk
JOIN household_demographics hd_cust
    ON sr.sr_hdemo_sk = hd_cust.hd_demo_sk
JOIN customer_address ca_cust
    ON sr.sr_addr_sk = ca_cust.ca_address_sk
JOIN income_band ib
    ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN item i_cat
    ON cr.cr_item_sk = i_cat.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON p.p_item_sk = i_cat.i_item_sk
WHERE p.p_discount_active = 'Y'
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_item_sk = i_store.i_item_sk
        AND cr2.cr_return_amount > 1000
  )
GROUP BY
    cp.cp_department,
    i_store.i_brand,
    p.p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
