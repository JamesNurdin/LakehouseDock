WITH
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ),
  base AS (
    SELECT
      d.d_year,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cr.cr_return_amount,
      wr.wr_return_amt,
      w.w_warehouse_name,
      ws.web_state,
      wp.wp_type,
      sr.sr_return_quantity,
      inv.inv_quantity_on_hand
    FROM date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
      AND cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    -- additional date_dim aliases for web_page creation and access dates
    JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM intersect_orders io WHERE io.order_number = cs.cs_order_number
      )
      AND NOT EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = cs.cs_item_sk
          AND inv2.inv_quantity_on_hand > 0
      )
  ),
  agg AS (
    SELECT
      d_year,
      hd_buy_potential,
      ib_lower_bound,
      ib_upper_bound,
      SUM(cs_quantity) AS total_quantity,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(wr_return_amt) AS total_web_return_amt,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM base
    GROUP BY ROLLUP (d_year, hd_buy_potential, ib_lower_bound, ib_upper_bound)
  )
SELECT
  d_year,
  hd_buy_potential,
  ib_lower_bound,
  ib_upper_bound,
  total_quantity,
  total_net_paid,
  total_return_amount,
  total_web_return_amt,
  total_on_hand,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS net_paid_rank
FROM agg
ORDER BY d_year DESC, hd_buy_potential
LIMIT 100
