/*
Goal: Produce a deep‑join analytical query that touches all 13 selected TPC‑DS tables, uses multiple aliases, samples fact tables, applies CASE logic, aggregates with ROLLUP, combines results with UNION ALL and a FULL OUTER JOIN, and returns the top 100 rows ordered by year and ship‑mode.
*/
WITH
  ss AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Fact side built from store_sales and its surrounding dimensions
  ss_fact AS (
    SELECT
      d.d_year                AS d_year,
      sm.sm_type              AS sm_type,
      ss.ss_net_paid          AS net_paid,
      ss.ss_net_profit        AS net_profit
    FROM ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk    = hd.hd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk     = ca.ca_address_sk
    /* Additional optional joins – left joins keep rows from store_sales */
    LEFT JOIN catalog_returns cr   ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN ship_mode sm        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r            ON cr.cr_reason_sk    = r.r_reason_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  -- Fact side built from web_sales and its surrounding dimensions
  ws_fact AS (
    SELECT
      d.d_year                AS d_year,
      sm.sm_type              AS sm_type,
      ws.ws_net_paid          AS net_paid,
      ws.ws_net_profit        AS net_profit
    FROM ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON ws.ws_bill_addr_sk  = ca.ca_address_sk
    LEFT JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  -- Union of the two fact streams (deduplication performed later by the outer SELECT)
  unified_fact AS (
    SELECT * FROM ss_fact
    UNION ALL
    SELECT * FROM ws_fact
  ),
  -- Helper table to guarantee a row for every (year, ship‑mode) combination
  year_ship AS (
    SELECT DISTINCT d.d_year, sm.sm_type
    FROM date_dim d
    CROSS JOIN ship_mode sm
  )
SELECT
  uf.d_year,
  uf.sm_type,
  CASE WHEN SUM(uf.net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
  SUM(uf.net_paid)   AS total_net_paid,
  SUM(uf.net_profit) AS total_net_profit
FROM unified_fact uf
FULL OUTER JOIN year_ship ys
  ON uf.d_year = ys.d_year AND uf.sm_type = ys.sm_type
GROUP BY ROLLUP (uf.d_year, uf.sm_type)
ORDER BY uf.d_year ASC NULLS LAST,
         uf.sm_type ASC NULLS LAST
OFFSET 0 FETCH NEXT 100 ROWS ONLY
