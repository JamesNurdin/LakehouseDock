WITH
  sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
  ),
  item_unnested AS (
    SELECT
      i_item_sk,
      i_item_id,
      i_brand_id,
      id AS unnested_item_id
    FROM sampled_items
    CROSS JOIN UNNEST(ARRAY[i_item_id]) AS t(id)
  ),
  cs_agg AS (
    SELECT
      cs_item_sk,
      cs_order_number,
      cs_catalog_page_sk,
      cs_promo_sk,
      cs_bill_hdemo_sk,
      cs_ship_hdemo_sk,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_order_number, cs_catalog_page_sk, cs_promo_sk, cs_bill_hdemo_sk, cs_ship_hdemo_sk
  ),
  joined AS (
    SELECT
      s.s_state,
      s.s_store_name,
      r.r_reason_desc,
      cs.total_net_paid,
      ws.ws_net_paid,
      sr.sr_net_loss,
      wr.wr_net_loss,
      cs.cs_order_number
    FROM cs_agg cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = cs.cs_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN item_unnested i ON i.i_item_sk = cs.cs_item_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND i.i_brand_id = 7004003
      AND ib.ib_lower_bound >= 30000
      AND cr.cr_refunded_cash > 100
      AND ws.ws_quantity > 5
      AND ib.ib_upper_bound < (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) - 10000
  )
SELECT
  s_state,
  s_store_name,
  r_reason_desc,
  SUM(total_net_paid) AS sum_sales,
  SUM(ws_net_paid) AS sum_web_sales,
  SUM(sr_net_loss) AS sum_store_loss,
  SUM(wr_net_loss) AS sum_web_loss,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(total_net_paid) DESC) AS state_rank
FROM joined
GROUP BY s_state, s_store_name, r_reason_desc
ORDER BY sum_sales DESC
LIMIT 100
