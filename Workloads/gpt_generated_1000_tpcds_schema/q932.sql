-- goal: Identify high‑versus low‑net‑paid sales periods across store and catalog channels, enriched with customer, promotion, demographic and operational dimensions.
WITH
  -- Sampled and pre‑aggregated store sales
  store_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_customer_sk,
      ss_promo_sk,
      SUM(ss_net_paid) AS total_net_paid
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 0
    GROUP BY ss_sold_date_sk, ss_customer_sk, ss_promo_sk
  ),
  -- Pre‑aggregated catalog sales (includes order linking fields)
  catalog_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_bill_customer_sk,
      cs_promo_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_order_number,
      SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_sold_date_sk,
             cs_bill_customer_sk,
             cs_promo_sk,
             cs_call_center_sk,
             cs_ship_mode_sk,
             cs_order_number
  ),
  -- Aggregated returns to bring in reason information
  returns_agg AS (
    SELECT
      cr_returned_date_sk,
      cr_order_number,
      cr_reason_sk,
      SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returned_date_sk, cr_order_number, cr_reason_sk
  ),
  -- Union of store‑side and catalog‑side rows (distinct by UNION)
  union_data AS (
    SELECT
      d1.d_date               AS sale_date,
      c.c_customer_id        AS customer_id,
      CASE
        WHEN sa.total_net_paid > (SELECT MAX(total_net_paid) FROM store_agg) THEN 'High'
        ELSE 'Low'
      END                     AS net_category,
      sa.total_net_paid       AS net_amount,
      p.p_promo_name          AS promo_name,
      cd.cd_gender            AS gender,
      hd.hd_buy_potential     AS buy_potential,
      ib.ib_lower_bound       AS income_lower_bound,
      wp.wp_type              AS web_page_type,
      cc.cc_name              AS call_center_name,
      NULL                    AS ship_mode_type,
      NULL                    AS return_reason,
      NULL                    AS return_amount
    FROM store_agg sa
    JOIN date_dim d1          ON sa.ss_sold_date_sk    = d1.d_date_sk
    JOIN customer c          ON sa.ss_customer_sk    = c.c_customer_sk
    JOIN promotion p         ON sa.ss_promo_sk       = p.p_promo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp        ON wp.wp_customer_sk   = c.c_customer_sk
    -- call_center linked through the date of opening (any call_center open on the sale date)
    JOIN call_center cc      ON cc.cc_open_date_sk   = d1.d_date_sk
    UNION
    SELECT
      d2.d_date               AS sale_date,
      c2.c_customer_id       AS customer_id,
      CASE
        WHEN ca.total_net_paid > (SELECT MAX(total_net_paid) FROM catalog_agg) THEN 'High'
        ELSE 'Low'
      END                     AS net_category,
      ca.total_net_paid       AS net_amount,
      p2.p_promo_name         AS promo_name,
      cd2.cd_gender           AS gender,
      hd2.hd_buy_potential    AS buy_potential,
      ib2.ib_lower_bound      AS income_lower_bound,
      wp2.wp_type             AS web_page_type,
      cc2.cc_name             AS call_center_name,
      sm2.sm_type             AS ship_mode_type,
      r.r_reason_desc         AS return_reason,
      ar.total_return_amount  AS return_amount
    FROM catalog_agg ca
    JOIN date_dim d2          ON ca.cs_sold_date_sk   = d2.d_date_sk
    JOIN customer c2          ON ca.cs_bill_customer_sk = c2.c_customer_sk
    JOIN promotion p2         ON ca.cs_promo_sk       = p2.p_promo_sk
    JOIN call_center cc2      ON ca.cs_call_center_sk = cc2.cc_call_center_sk
    JOIN ship_mode sm2        ON ca.cs_ship_mode_sk   = sm2.sm_ship_mode_sk
    JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2      ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN web_page wp2        ON wp2.wp_customer_sk   = c2.c_customer_sk
    LEFT JOIN returns_agg ar ON ar.cr_order_number   = ca.cs_order_number
    LEFT JOIN reason r       ON ar.cr_reason_sk      = r.r_reason_sk
  )
SELECT
  net_category,
  COUNT(DISTINCT sale_date)               AS distinct_sale_days,
  SUM(net_amount)                         AS total_net_amount,
  AVG(net_amount)                         AS avg_net_amount,
  COUNT(DISTINCT customer_id)             AS distinct_customers,
  COUNT(DISTINCT promo_name)              AS distinct_promotions,
  COUNT(DISTINCT call_center_name)        AS distinct_call_centers,
  COUNT(DISTINCT ship_mode_type)          AS distinct_ship_modes,
  COUNT(DISTINCT return_reason)           AS distinct_return_reasons
FROM union_data
GROUP BY net_category
ORDER BY net_category DESC
LIMIT 100
