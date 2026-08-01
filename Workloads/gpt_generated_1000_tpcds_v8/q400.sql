/*
  Goal: Identify high‑profit catalog sales, enriched with customer, promotion and warehouse details, rank them per state, classify profit/loss, and compare two yearly slices (2001 vs 2002) using UNION, INTERSECT, window functions, CASE logic, a correlated subquery, and a LATERAL aggregation. The result is ordered by profit and limited to the top 100 rows.
*/
WITH
  /* Join every selected table according to the allowed keys */
  joined_all AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit                               AS net_profit,
      cs.cs_ext_sales_price,
      d.d_year,
      ca_bill.ca_state,
      sm.sm_code,
      w.w_state,
      p.p_promo_sk,
      ss.ss_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    /* Store Sales – same date and time dimensions */
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = td.t_time_sk
    /* Inventory – same date and warehouse */
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    /* Web Returns and its related dimensions */
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim wr_td
      ON wr.wr_returned_time_sk = wr_td.t_time_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    /* Web Site – opened on the same date */
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
  )
,
  /* First slice: year 2001, CA, AIR */
  slice_one AS (
    SELECT
      ja.cs_order_number,
      ja.net_profit,
      ja.d_year,
      ja.ca_state,
      ja.sm_code,
      CASE WHEN ja.net_profit > 0 THEN 'Profit' ELSE 'Loss' END               AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY ja.w_state ORDER BY ja.net_profit DESC) AS profit_rank_state,
      (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = ja.ss_customer_sk) AS customer_sales_count,
      lp.avg_sales_price
    FROM joined_all ja
    LEFT JOIN LATERAL (
      SELECT AVG(cs3.cs_ext_sales_price) AS avg_sales_price
      FROM catalog_sales cs3
      WHERE cs3.cs_promo_sk = ja.p_promo_sk
    ) lp ON TRUE
    WHERE ja.d_year = 2001
      AND ja.ca_state = 'CA'
      AND ja.sm_code = 'AIR'
  ),
  /* Second slice: year 2002, NY, SEA */
  slice_two AS (
    SELECT
      ja.cs_order_number,
      ja.net_profit,
      ja.d_year,
      ja.ca_state,
      ja.sm_code,
      CASE WHEN ja.net_profit > 0 THEN 'Profit' ELSE 'Loss' END               AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY ja.w_state ORDER BY ja.net_profit DESC) AS profit_rank_state,
      (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = ja.ss_customer_sk) AS customer_sales_count,
      lp.avg_sales_price
    FROM joined_all ja
    LEFT JOIN LATERAL (
      SELECT AVG(cs3.cs_ext_sales_price) AS avg_sales_price
      FROM catalog_sales cs3
      WHERE cs3.cs_promo_sk = ja.p_promo_sk
    ) lp ON TRUE
    WHERE ja.d_year = 2002
      AND ja.ca_state = 'NY'
      AND ja.sm_code = 'SEA'
  ),
  /* Union of the two slices (deduped) */
  union_set AS (
    SELECT * FROM slice_one
    UNION DISTINCT
    SELECT * FROM slice_two
  ),
  /* A third query that overlaps both slices – used for INTERSECT */
  intersect_source AS (
    SELECT
      ja.cs_order_number,
      ja.net_profit,
      ja.d_year,
      ja.ca_state,
      ja.sm_code,
      CASE WHEN ja.net_profit > 0 THEN 'Profit' ELSE 'Loss' END               AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY ja.w_state ORDER BY ja.net_profit DESC) AS profit_rank_state,
      (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = ja.ss_customer_sk) AS customer_sales_count,
      lp.avg_sales_price
    FROM joined_all ja
    LEFT JOIN LATERAL (
      SELECT AVG(cs3.cs_ext_sales_price) AS avg_sales_price
      FROM catalog_sales cs3
      WHERE cs3.cs_promo_sk = ja.p_promo_sk
    ) lp ON TRUE
    WHERE ja.d_year IN (2001, 2002)
      AND ja.ca_state IN ('CA', 'NY')
      AND ja.sm_code IN ('AIR', 'SEA')
  )
/* Final result: rows that appear in both the union set and the intersect source */
SELECT *
FROM union_set
INTERSECT
SELECT *
FROM intersect_source
ORDER BY net_profit DESC
LIMIT 100
