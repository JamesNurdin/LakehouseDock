WITH
  -- 10% random sample of store_sales to reduce data volume
  ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Aggregated promotion info per item
  promo_agg AS (
    SELECT p_item_sk,
           COUNT(*) AS promo_cnt,
           SUM(p_cost) AS total_promo_cost
    FROM promotion
    GROUP BY p_item_sk
  ),
  -- Generate a tiny array column that we will unnest later
  array_data AS (
    SELECT p_promo_sk,
           ARRAY['A','B','C'] AS codes
    FROM promotion
    LIMIT 5
  ),
  unnest_codes AS (
    SELECT ad.p_promo_sk,
           code
    FROM array_data ad
    CROSS JOIN UNNEST(ad.codes) AS t(code)
  ),
  -- Small dimension to be cross‑joined with a computed set
  small_ship AS (
    SELECT sm_ship_mode_id
    FROM ship_mode
    LIMIT 5
  ),
  computed_set AS (
    SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
  )
SELECT
  s.s_store_name,
  i.i_item_id,
  c.c_customer_id,
  hd_cur.hd_buy_potential,
  ib.ib_lower_bound,
  sm2.sm_ship_mode_id,
  CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS return_status,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(cr.cr_return_amount) AS total_returns,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  SUM(pa.promo_cnt) AS total_promos,
  -- demonstrate use of the cross‑joined computed set
  cs.dummy AS cross_dummy,
  -- demonstrate use of an unnested code
  uc.code AS promo_code
FROM ss_sample ss
  -- cartesian product with a tiny ship_mode slice and a computed set
  CROSS JOIN small_ship ss_cross
  CROSS JOIN computed_set cs
  JOIN store s               ON ss.ss_store_sk   = s.s_store_sk
  JOIN item i                ON ss.ss_item_sk    = i.i_item_sk
  JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd_cur ON ss.ss_hdemo_sk = hd_cur.hd_demo_sk
  JOIN income_band ib        ON hd_cur.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca   ON ss.ss_addr_sk    = ca.ca_address_sk
  JOIN promotion p           ON ss.ss_promo_sk   = p.p_promo_sk
  JOIN promo_agg pa          ON p.p_item_sk      = pa.p_item_sk
  JOIN unnest_codes uc       ON p.p_promo_sk     = uc.p_promo_sk
  JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN catalog_returns cr   ON cr.cr_item_sk = i.i_item_sk
                           AND cr.cr_returned_time_sk = td.t_time_sk
  JOIN ship_mode sm2         ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN customer c_ret        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
  JOIN web_page wp           ON wp.wp_customer_sk = c.c_customer_sk
WHERE s.s_state = 'CA'
GROUP BY
  s.s_store_name,
  i.i_item_id,
  c.c_customer_id,
  hd_cur.hd_buy_potential,
  ib.ib_lower_bound,
  sm2.sm_ship_mode_id,
  CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END,
  cs.dummy,
  uc.code
ORDER BY total_sales DESC
LIMIT 100
