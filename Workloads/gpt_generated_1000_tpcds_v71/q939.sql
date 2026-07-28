WITH
  base AS (
    SELECT
      d.d_year,
      c.c_customer_id,
      hd.hd_demo_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      p.p_promo_id,
      p.p_discount_active,
      w.w_warehouse_id,
      w.w_warehouse_sq_ft,
      sm.sm_type,
      cs.cs_net_profit               AS catalog_net_profit,
      ss.ss_net_paid                 AS store_net_paid,
      ws.ws_net_profit               AS web_net_profit,
      sr.sr_return_amt               AS store_return_amt,
      r.r_reason_desc,
      inv.inv_quantity_on_hand,
      wp.wp_url,
      we.web_city
    FROM catalog_sales cs
      JOIN date_dim d                ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
      JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
      JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
      JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
      JOIN store_sales ss            ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN store_returns sr          ON sr.sr_returned_date_sk = d.d_date_sk
                                      AND sr.sr_ticket_number = ss.ss_ticket_number
      JOIN reason r                  ON sr.sr_reason_sk = r.r_reason_sk
      JOIN inventory inv             ON inv.inv_date_sk = d.d_date_sk
                                      AND inv.inv_warehouse_sk = w.w_warehouse_sk
      JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN web_site we               ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND w.w_warehouse_sq_ft > 500000
      AND p.p_discount_active = 'Y'
      AND we.web_county = 'Maverick County'
      AND ib.ib_lower_bound > 50000
  ),
  agg AS (
    SELECT
      d_year,
      p_promo_id,
      w_warehouse_id,
      SUM(catalog_net_profit) AS total_catalog_profit,
      SUM(store_net_paid)     AS total_store_paid,
      SUM(web_net_profit)     AS total_web_profit,
      SUM(store_return_amt)   AS total_store_return,
      COUNT(*)                AS txn_cnt
    FROM base
    GROUP BY GROUPING SETS (
      (d_year, p_promo_id, w_warehouse_id),
      (d_year, p_promo_id),
      (d_year),
      ()
    )
  )
SELECT
  a.d_year,
  a.p_promo_id,
  a.w_warehouse_id,
  a.total_catalog_profit,
  a.total_store_paid,
  a.total_web_profit,
  a.total_store_return,
  a.txn_cnt
FROM agg a
WHERE NOT EXISTS (
  SELECT 1
  FROM store_returns sr2
    JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
  WHERE d2.d_year = a.d_year
    AND r2.r_reason_desc = 'Damaged'
)
ORDER BY a.d_year DESC, a.p_promo_id, a.w_warehouse_id
LIMIT 100
