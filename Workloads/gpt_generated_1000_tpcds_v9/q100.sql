/* Goal: Analyze store, catalog, and web sales performance by store, year, and state, filter to high net revenue stores, exclude customers with any returns, include call‑center and web‑site open‑year info via a full outer join, and compute rankings and lagged net‑paid values. */
WITH
  -- Call‑center open‑year per call‑center
  cc_dates AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      d.d_year AS open_year
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
  ),
  -- Web‑site open‑year per site
  we_dates AS (
    SELECT
      we.web_site_sk,
      we.web_name,
      d.d_year AS open_year
    FROM web_site we
    JOIN date_dim d ON we.web_open_date_sk = d.d_date_sk
  ),
  -- Full outer join of the two open‑year sets (keeps unmatched rows from both sides)
  cc_we_full AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      we.web_site_sk,
      we.web_name,
      COALESCE(cc.open_year, we.open_year) AS open_year
    FROM cc_dates cc
    FULL OUTER JOIN we_dates we ON cc.open_year = we.open_year
  ),
  -- Core aggregation joining all fact and dimension tables
  aggregated AS (
    SELECT
      s.s_store_name,
      d.d_year AS store_year,
      ca.ca_state,
      SUM(ss.ss_net_paid) AS total_store_net_paid,
      SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
      SUM(ws.ws_net_paid) AS total_web_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
      AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM store_returns sr2 WHERE sr2.sr_customer_sk = c.c_customer_sk
    )
    GROUP BY ROLLUP (s.s_store_name, d.d_year, ca.ca_state)
    HAVING SUM(ss.ss_net_paid) > 10000
  )
SELECT
  agg.s_store_name,
  agg.store_year,
  agg.ca_state,
  agg.total_store_net_paid,
  agg.total_catalog_sales,
  agg.total_web_sales,
  ROW_NUMBER() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_store_net_paid DESC) AS rn_store,
  LAG(agg.total_store_net_paid) OVER (PARTITION BY agg.s_store_name ORDER BY agg.store_year) AS lag_store_net_paid,
  cc_we_full.cc_name,
  cc_we_full.web_name,
  cc_we_full.open_year
FROM aggregated agg
LEFT JOIN cc_we_full ON agg.store_year = cc_we_full.open_year
ORDER BY agg.total_store_net_paid DESC
LIMIT 100
