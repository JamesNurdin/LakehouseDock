WITH
  -- Aggregate net paid per web site (only rows with noticeable tax) and rank each site
  sales_by_site_raw AS (
    SELECT ws.ws_web_site_sk,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM   web_sales ws
    WHERE  ws.ws_ext_tax > 20
    GROUP BY ws.ws_web_site_sk
  ),
  sales_by_site AS (
    SELECT ws_web_site_sk,
           total_net_paid,
           ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY total_net_paid DESC) AS sales_rank
    FROM   sales_by_site_raw
  ),

  -- Join web sales to household demographics via the billing household key
  demo_sales AS (
    SELECT ws.ws_web_site_sk,
           hd.hd_buy_potential,
           SUM(ws.ws_net_paid) AS demo_total_net_paid
    FROM   web_sales ws
    JOIN   household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY ws.ws_web_site_sk, hd.hd_buy_potential
  ),

  -- Full outer join the two site‑level aggregates so we keep rows that exist in one side only
  full_agg AS (
    SELECT COALESCE(s.ws_web_site_sk, d.ws_web_site_sk) AS web_site_sk,
           s.total_net_paid,
           s.sales_rank,
           d.hd_buy_potential,
           d.demo_total_net_paid
    FROM   sales_by_site s
    FULL OUTER JOIN demo_sales d ON s.ws_web_site_sk = d.ws_web_site_sk
  ),

  -- Right outer join to the web_site dimension to retain every site (even without sales)
  right_joined AS (
    SELECT ws.web_site_sk,
           ws.web_name,
           fa.total_net_paid,
           fa.sales_rank,
           fa.hd_buy_potential,
           fa.demo_total_net_paid
    FROM   web_site ws
    RIGHT OUTER JOIN full_agg fa ON ws.web_site_sk = fa.web_site_sk
  ),

  -- Add subtotal rows with ROLLUP and compute the final net‑paid sum per site / buy‑potential
  rollup_agg AS (
    SELECT web_site_sk,
           hd_buy_potential,
           SUM(COALESCE(total_net_paid, 0) + COALESCE(demo_total_net_paid, 0)) AS sum_net_paid,
           sales_rank
    FROM   right_joined
    GROUP BY ROLLUP (web_site_sk, hd_buy_potential, sales_rank)
  ),

  -- Identify sites that have never appeared in web_sales (EXCEPT operation)
  sites_without_sales AS (
    SELECT web_site_sk FROM web_site
    EXCEPT
    SELECT DISTINCT ws_web_site_sk FROM web_sales
  )

SELECT
  web_site_sk,
  hd_buy_potential,
  sum_net_paid,
  sales_rank
FROM   rollup_agg
UNION ALL
SELECT
  sws.web_site_sk,
  NULL            AS hd_buy_potential,
  0.0             AS sum_net_paid,
  NULL            AS sales_rank
FROM   sites_without_sales sws
LIMIT 100
