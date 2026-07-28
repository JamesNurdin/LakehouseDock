WITH
  c_sales_agg AS (
    SELECT
      cs_item_sk,
      cs_promo_sk,
      cs_ship_mode_sk,
      MIN(cs_sold_date_sk) AS sold_date_sk,
      MIN(cs_bill_cdemo_sk) AS bill_cdemo_sk,
      MIN(cs_bill_hdemo_sk) AS bill_hdemo_sk,
      MIN(cs_ship_cdemo_sk) AS ship_cdemo_sk,
      MIN(cs_ship_hdemo_sk) AS ship_hdemo_sk,
      SUM(cs_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000 AND d_month_seq BETWEEN 1200 AND 1210
    )
    GROUP BY cs_item_sk, cs_promo_sk, cs_ship_mode_sk
    HAVING SUM(cs_net_paid) > 10000
  ),
  s_sales_agg AS (
    SELECT
      ss_item_sk,
      ss_store_sk,
      ss_promo_sk,
      MIN(ss_sold_date_sk) AS sold_date_sk,
      MIN(ss_cdemo_sk) AS cdemo_sk,
      MIN(ss_hdemo_sk) AS hdemo_sk,
      SUM(ss_net_paid) AS store_total_paid,
      COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2000 AND d_month_seq BETWEEN 1200 AND 1210
    )
    GROUP BY ss_item_sk, ss_store_sk, ss_promo_sk
  ),
  inventory_recent AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
    GROUP BY inv_item_sk
  ),
  web_site_recent AS (
    SELECT *
    FROM web_site
    WHERE web_open_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 1999)
  ),
  web_page_recent AS (
    SELECT wp_web_page_sk, wp_url, wp_type, wp_creation_date_sk, wp_access_date_sk
    FROM web_page
    WHERE wp_creation_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
  )
,
  catalog_part AS (
    SELECT
      ca.cs_item_sk AS item_sk,
      ca.total_net_paid AS amount,
      'catalog' AS src,
      RANK() OVER (ORDER BY ca.total_net_paid DESC) AS revenue_rank,
      ca.sold_date_sk,
      ca.bill_cdemo_sk AS cdemo_sk,
      ca.bill_hdemo_sk AS hdemo_sk,
      ca.cs_promo_sk AS promo_sk,
      ca.cs_ship_mode_sk AS ship_mode_sk
    FROM c_sales_agg ca
    JOIN promotion p ON ca.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_discount_active = 'Y' AND sm.sm_type = 'OVER NIGHT'
  ),
  store_part AS (
    SELECT
      sa.ss_item_sk AS item_sk,
      sa.store_total_paid AS amount,
      'store' AS src,
      ROW_NUMBER() OVER (ORDER BY sa.store_total_paid DESC) AS revenue_rank,
      sa.sold_date_sk,
      sa.cdemo_sk,
      sa.hdemo_sk,
      sa.ss_promo_sk AS promo_sk,
      NULL AS ship_mode_sk
    FROM s_sales_agg sa
    JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
  ),
  combined AS (
    SELECT * FROM catalog_part
    UNION ALL
    SELECT * FROM store_part
  )
SELECT DISTINCT
  c.item_sk,
  c.src,
  c.amount,
  c.revenue_rank,
  d.d_date,
  cd.cd_gender,
  hd.hd_income_band_sk,
  p.p_promo_name,
  sm.sm_carrier,
  i.total_on_hand,
  ws.wp_url,
  wsv.web_state,
  /* correlated sub‑query: total return amount for the same item */
  (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
   FROM catalog_returns cr
   WHERE cr.cr_item_sk = c.item_sk) AS total_catalog_return_amount,
  /* CASE example: flag high profit items */
  CASE WHEN c.amount > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_flag
FROM combined c
LEFT JOIN date_dim d ON c.sold_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd ON c.cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON c.hdemo_sk = hd.hd_demo_sk
LEFT JOIN promotion p ON c.promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm ON c.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory_recent i ON c.item_sk = i.inv_item_sk
LEFT JOIN web_page_recent ws ON d.d_date_sk = ws.wp_creation_date_sk
LEFT JOIN web_site_recent wsv ON d.d_date_sk = wsv.web_open_date_sk
WHERE d.d_year = 2000
  AND cd.cd_gender = 'M'
  AND hd.hd_income_band_sk BETWEEN 3 AND 5
  AND i.total_on_hand > 0
  AND wsv.web_state = 'CA'
  AND sm.sm_carrier = 'MSC'
ORDER BY c.revenue_rank
LIMIT 100
