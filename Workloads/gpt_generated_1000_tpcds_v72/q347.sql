WITH
  -- Combine the three sales fact tables into a single stream
  unified_sales AS (
    SELECT
      cs.cs_sold_date_sk            AS sold_date_sk,
      cs.cs_sold_time_sk            AS sold_time_sk,
      cs.cs_item_sk                 AS item_sk,
      cs.cs_bill_customer_sk        AS bill_customer_sk,
      cs.cs_bill_cdemo_sk           AS bill_cdemo_sk,
      cs.cs_bill_hdemo_sk           AS bill_hdemo_sk,
      cs.cs_bill_addr_sk            AS bill_addr_sk,
      cs.cs_ship_customer_sk        AS ship_customer_sk,
      cs.cs_ship_cdemo_sk           AS ship_cdemo_sk,
      cs.cs_ship_hdemo_sk           AS ship_hdemo_sk,
      cs.cs_ship_addr_sk            AS ship_addr_sk,
      cs.cs_call_center_sk          AS call_center_sk,
      cs.cs_catalog_page_sk         AS catalog_page_sk,
      cs.cs_ship_mode_sk            AS ship_mode_sk,
      cs.cs_promo_sk                AS promo_sk,
      cs.cs_order_number            AS order_number,
      cs.cs_quantity                AS quantity,
      cs.cs_net_profit              AS net_profit,
      NULL                          AS store_sk,
      NULL                          AS web_site_sk
    FROM catalog_sales cs

    UNION ALL

    SELECT
      ss.ss_sold_date_sk            AS sold_date_sk,
      ss.ss_sold_time_sk            AS sold_time_sk,
      ss.ss_item_sk                 AS item_sk,
      ss.ss_customer_sk             AS bill_customer_sk,
      ss.ss_cdemo_sk                AS bill_cdemo_sk,
      ss.ss_hdemo_sk                AS bill_hdemo_sk,
      ss.ss_addr_sk                 AS bill_addr_sk,
      NULL                          AS ship_customer_sk,
      NULL                          AS ship_cdemo_sk,
      NULL                          AS ship_hdemo_sk,
      NULL                          AS ship_addr_sk,
      NULL                          AS call_center_sk,
      NULL                          AS catalog_page_sk,
      NULL                          AS ship_mode_sk,
      ss.ss_promo_sk                AS promo_sk,
      ss.ss_ticket_number           AS order_number,
      ss.ss_quantity                AS quantity,
      ss.ss_net_profit              AS net_profit,
      ss.ss_store_sk                AS store_sk,
      NULL                          AS web_site_sk
    FROM store_sales ss

    UNION ALL

    SELECT
      ws.ws_sold_date_sk            AS sold_date_sk,
      ws.ws_sold_time_sk            AS sold_time_sk,
      ws.ws_item_sk                 AS item_sk,
      ws.ws_bill_customer_sk        AS bill_customer_sk,
      ws.ws_bill_cdemo_sk           AS bill_cdemo_sk,
      ws.ws_bill_hdemo_sk           AS bill_hdemo_sk,
      ws.ws_bill_addr_sk            AS bill_addr_sk,
      ws.ws_ship_customer_sk        AS ship_customer_sk,
      ws.ws_ship_cdemo_sk           AS ship_cdemo_sk,
      ws.ws_ship_hdemo_sk           AS ship_hdemo_sk,
      ws.ws_ship_addr_sk            AS ship_addr_sk,
      NULL                          AS call_center_sk,
      NULL                          AS catalog_page_sk,
      ws.ws_ship_mode_sk            AS ship_mode_sk,
      ws.ws_promo_sk                AS promo_sk,
      ws.ws_order_number            AS order_number,
      ws.ws_quantity                AS quantity,
      ws.ws_net_profit              AS net_profit,
      NULL                          AS store_sk,
      ws.ws_web_site_sk             AS web_site_sk
    FROM web_sales ws
  ),

  -- Apply filters, join to all dimension/reference tables, and exclude rows that have a return record
  filtered_sales AS (
    SELECT
      us.*,
      d.d_year,
      d.d_month_seq,
      t.t_sub_shift,
      i.i_category,
      i.i_category_id,
      ca.ca_suite_number,
      sm.sm_type,
      p.p_discount_active,
      cc.cc_name,
      cp.cp_department,
      s.s_store_name,
      ws_site.web_name,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc
    FROM unified_sales us
    -- Date and Time dimensions
    JOIN date_dim d           ON us.sold_date_sk = d.d_date_sk
    JOIN time_dim t           ON us.sold_time_sk = t.t_time_sk
    -- Item and its attributes
    JOIN item i                ON us.item_sk = i.i_item_sk
    -- Customer related dimensions (bill side)
    LEFT JOIN customer c      ON us.bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON us.bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON us.bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON us.bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- Optional joins for fields that may be null in some fact sources
    LEFT JOIN call_center cc   ON us.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp   ON us.catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm      ON us.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p       ON us.promo_sk = p.p_promo_sk
    LEFT JOIN store s           ON us.store_sk = s.s_store_sk
    LEFT JOIN web_site ws_site  ON us.web_site_sk = ws_site.web_site_sk
    -- Reason (joined via return tables – we left‑join the return tables first and then the reason)
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = us.order_number
    LEFT JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
    -- Filters (at least four predicates)
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category_id IN (1, 5, 9)
      AND ca.ca_suite_number = 'Suite 280'
      AND t.t_sub_shift = 'morning'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      -- Exclude any sales that have a return record (anti‑join)
      AND NOT EXISTS (SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = us.order_number)
      AND NOT EXISTS (SELECT 1 FROM web_returns wr2    WHERE wr2.wr_order_number = us.order_number)
  ),

  -- Aggregate profit per customer, category and year
  profit_by_cust AS (
    SELECT
      c.c_customer_id,
      i.i_category,
      d.d_year,
      SUM(us.net_profit) AS total_profit
    FROM filtered_sales us
    JOIN customer c          ON us.bill_customer_sk = c.c_customer_sk
    JOIN item i              ON us.item_sk = i.i_item_sk
    JOIN date_dim d          ON us.sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id, i.i_category, d.d_year
  )

SELECT
  pbc.c_customer_id,
  pbc.i_category,
  pbc.d_year,
  pbc.total_profit,
  RANK() OVER (PARTITION BY pbc.d_year ORDER BY pbc.total_profit DESC) AS profit_rank
FROM profit_by_cust pbc
WHERE pbc.total_profit > 0
ORDER BY pbc.d_year, profit_rank
LIMIT 100
