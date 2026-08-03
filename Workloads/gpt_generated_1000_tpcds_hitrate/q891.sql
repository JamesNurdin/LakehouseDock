WITH
  catalog_data AS (
    SELECT
      cs.cs_sold_date_sk          AS sold_date_sk,
      cs.cs_item_sk               AS item_sk,
      cs.cs_quantity              AS quantity,
      cs.cs_net_paid              AS net_paid,
      i.i_category                AS category,
      i.i_brand                   AS brand,
      p.p_discount_active         AS promo_active,
      cc.cc_name                  AS call_center_name,
      cp.cp_type                  AS catalog_page_type,
      sm.sm_type                  AS ship_mode_type,
      w.w_state                   AS warehouse_state,
      ca.ca_state                 AS customer_state,
      ca.ca_country               AS customer_country,
      cd.cd_credit_rating         AS credit_rating,
      hd.hd_income_band_sk        AS income_band_sk,
      ib.ib_lower_bound           AS income_lower,
      ib.ib_upper_bound           AS income_upper
    FROM catalog_sales cs
    JOIN item i                 ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p            ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm           ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w            ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca    ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
  ),
  store_data AS (
    SELECT
      ss.ss_sold_date_sk          AS sold_date_sk,
      ss.ss_item_sk               AS item_sk,
      ss.ss_quantity              AS quantity,
      ss.ss_net_paid              AS net_paid,
      i.i_category                AS category,
      i.i_brand                   AS brand,
      p.p_discount_active         AS promo_active,
      w.w_state                   AS warehouse_state,
      ca.ca_state                 AS customer_state,
      ca.ca_country               AS customer_country,
      cd.cd_credit_rating         AS credit_rating,
      hd.hd_income_band_sk        AS income_band_sk,
      ib.ib_lower_bound           AS income_lower,
      ib.ib_upper_bound           AS income_upper
    FROM store_sales ss
    JOIN item i                 ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p            ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca    ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv           ON ss.ss_item_sk = inv.inv_item_sk
    JOIN warehouse w            ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE w.w_state = 'CA'
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
      AND cd.cd_credit_rating IN ('Good', 'High Risk')
  ),
  overall_avg AS (
    SELECT AVG(net_paid) AS avg_net_paid
    FROM (
      SELECT net_paid FROM catalog_data
      UNION
      SELECT net_paid FROM store_data
    ) a
  )
SELECT
  category,
  brand,
  SUM(net_paid) AS total_net_paid,
  SUM(quantity) AS total_quantity,
  CASE
    WHEN SUM(net_paid) > (SELECT avg_net_paid FROM overall_avg) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS performance
FROM (
  SELECT category, brand, net_paid, quantity FROM catalog_data
  UNION
  SELECT category, brand, net_paid, quantity FROM store_data
) combined
GROUP BY category, brand
HAVING SUM(quantity) > 100
ORDER BY total_net_paid DESC
LIMIT 100
