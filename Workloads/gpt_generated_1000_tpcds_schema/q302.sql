WITH
  promo_map AS (
    SELECT
      p.p_promo_sk,
      MAP(ARRAY['promo_id', 'promo_name'], ARRAY[p.p_promo_id, p.p_promo_name]) AS promo_info
    FROM promotion p
  ),
  sales_detail AS (
    SELECT
      cs.cs_sold_date_sk,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      i.i_category,
      cp.cp_department,
      sm.sm_carrier,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      inv.inv_quantity_on_hand,
      wp.wp_url,
      ws.web_name,
      cs.cs_net_paid,
      cs.cs_ext_sales_price,
      pm.promo_info,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_sold_time_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk AND i.i_item_sk = inv.inv_item_sk
    LEFT JOIN web_page wp ON d.d_date_sk = wp.wp_creation_date_sk
    LEFT JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
    LEFT JOIN promo_map pm ON cs.cs_promo_sk = pm.p_promo_sk
  ),
  returns_detail AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      d.d_year,
      i.i_category,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_returned_date_sk, d.d_year, i.i_category
  ),
  full_returns AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_return_amt,
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_amt
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
      ON sr.sr_item_sk = wr.wr_item_sk
     AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
  ),
  union_data AS (
    SELECT
      sd.cs_sold_date_sk AS date_sk,
      d.d_year,
      sd.i_category,
      sd.cs_net_paid AS metric,
      sd.promo_info
    FROM sales_detail sd
    JOIN date_dim d ON sd.cs_sold_date_sk = d.d_date_sk
    UNION DISTINCT
    SELECT
      rd.date_sk,
      rd.d_year,
      rd.i_category,
      rd.total_return_amt AS metric,
      CAST(NULL AS map(varchar, varchar)) AS promo_info
    FROM returns_detail rd
  )
SELECT
  ud.date_sk,
  d.d_date,
  ud.d_year,
  ud.i_category,
  SUM(ud.metric) AS total_metric,
  COUNT(*) AS row_cnt,
  promo_key,
  promo_value
FROM union_data ud
JOIN date_dim d ON ud.date_sk = d.d_date_sk
LEFT JOIN UNNEST(ud.promo_info) AS t (promo_key, promo_value) ON TRUE
GROUP BY
  ud.date_sk,
  d.d_date,
  ud.d_year,
  ud.i_category,
  promo_key,
  promo_value
ORDER BY total_metric DESC
LIMIT 100
