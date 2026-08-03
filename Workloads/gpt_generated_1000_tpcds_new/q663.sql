WITH
  intersect_items AS (
    SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 1
    INTERSECT
    SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount > 100
  ),
  catalog_returns_daily AS (
    SELECT
      cr_returned_date_sk AS date_sk,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_net_loss) AS total_net_loss,
      MIN(cr_reason_sk) AS reason_sk
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2000
      )
    GROUP BY cr_returned_date_sk
  ),
  store_returns_agg AS (
    SELECT
      sr_store_sk,
      sr_returned_date_sk AS date_sk,
      SUM(sr_net_loss) AS total_store_net_loss,
      SUM(sr_return_amt) AS total_store_return_amt,
      sr_reason_sk
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_store_sk, sr_returned_date_sk, sr_reason_sk
  ),
  combined_returns AS (
    SELECT
      COALESCE(c.date_sk, s.date_sk)               AS date_sk,
      c.total_return_amount,
      c.total_net_loss,
      s.total_store_net_loss,
      s.total_store_return_amt,
      COALESCE(c.reason_sk, s.sr_reason_sk)       AS reason_sk,
      s.sr_store_sk
    FROM catalog_returns_daily c
    FULL OUTER JOIN store_returns_agg s
      ON c.date_sk = s.date_sk
  ),
  enriched_returns AS (
    SELECT
      d.d_year,
      st.s_store_name,
      st.s_state,
      inv.inv_quantity_on_hand,
      ws.ws_order_number,
      ws.ws_quantity,
      p.p_promo_name,
      p.p_discount_active,
      r.r_reason_desc,
      COALESCE(cr.total_store_net_loss, 0) + COALESCE(cr.total_net_loss, 0) AS net_loss
    FROM combined_returns cr
    JOIN date_dim d ON cr.date_sk = d.d_date_sk
    LEFT JOIN reason r ON cr.reason_sk = r.r_reason_sk
    LEFT JOIN store st ON cr.sr_store_sk = st.s_store_sk
    LEFT JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
      AND ws.ws_item_sk IN (SELECT ws_item_sk FROM intersect_items)
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2000
      AND st.s_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 100
  ),
  store_year_agg AS (
    SELECT
      d_year,
      s_store_name,
      SUM(net_loss) AS yearly_net_loss,
      CASE WHEN SUM(net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS loss_category
    FROM enriched_returns
    GROUP BY d_year, s_store_name
  ),
  ranked_stores AS (
    SELECT
      d_year,
      s_store_name,
      yearly_net_loss,
      loss_category,
      RANK() OVER (PARTITION BY d_year ORDER BY yearly_net_loss DESC) AS store_rank
    FROM store_year_agg
  )
SELECT
  d_year,
  s_store_name,
  yearly_net_loss,
  loss_category,
  store_rank
FROM ranked_stores
WHERE store_rank <= 5
ORDER BY d_year, store_rank
LIMIT 100
