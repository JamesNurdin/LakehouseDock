WITH
  /* distinct list of items – uses DISTINCT */
  distinct_items AS (
    SELECT DISTINCT i_item_sk, i_item_id
    FROM item
  ),
  /* base join of all 16 tables */
  base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      d.d_year,
      t.t_hour,
      i.i_current_price,
      cd.cd_gender,
      hd.hd_buy_potential,
      w.w_state,
      sm.sm_type,
      wp.wp_type,
      site.web_name,
      sr.sr_return_quantity,
      r.r_reason_desc,
      inv.inv_quantity_on_hand,
      ib.ib_lower_bound,
      cc.cc_name,
      cp.cp_department,
      di.i_item_id
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN distinct_items di        ON ws.ws_item_sk = di.i_item_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site            ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN store_returns sr    ON sr.sr_item_sk = ws.ws_item_sk
                                   AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
    LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv       ON inv.inv_item_sk = ws.ws_item_sk
                                   AND inv.inv_date_sk = d.d_date_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN call_center cc      ON cc.cc_open_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_page cp      ON cp.cp_start_date_sk = ws.ws_sold_date_sk
  ),
  /* aggregation with GROUPING SETS */
  agg AS (
    SELECT
      d_year,
      i_item_id,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit)      AS total_profit,
      COUNT(DISTINCT ws_order_number) AS distinct_orders,
      CASE
        WHEN SUM(ws_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(ws_ext_sales_price) > 50000  THEN 'Medium'
        ELSE 'Low'
      END AS sales_category
    FROM base
    WHERE i_current_price > 50                 -- predicate 1
      AND t_hour BETWEEN 9 AND 17               -- predicate 2
      AND w_state = 'CA'                         -- predicate 3
      AND EXISTS (                               -- predicate 4 (subquery)
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = base.ws_item_sk
              AND sr2.sr_return_quantity > 0
          )
    GROUP BY GROUPING SETS (
      (d_year, i_item_id),
      (d_year),
      ()
    )
  )
SELECT
  d_year,
  i_item_id,
  total_sales,
  total_profit,
  distinct_orders,
  sales_category,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
