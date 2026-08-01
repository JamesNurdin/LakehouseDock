WITH
  inventory_daily AS (
    SELECT
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk
  ),
  call_center_daily AS (
    SELECT
      cc_open_date_sk AS date_sk,
      COUNT(*) AS cc_count,
      MAX(cc_tax_percentage) AS max_tax
    FROM call_center
    GROUP BY cc_open_date_sk
  ),
  web_site_daily AS (
    SELECT
      web_open_date_sk AS date_sk,
      COUNT(*) AS site_count
    FROM web_site
    GROUP BY web_open_date_sk
  ),
  sales_agg AS (
    SELECT
      s.s_store_name,
      d.d_year,
      SUM(ss.ss_net_profit) AS total_net_profit,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_quantity,
      AVG(ss.ss_ext_tax) AS avg_tax,
      COUNT(*) AS sales_transactions,
      CASE
        WHEN MAX(s.s_state) = 'CA' THEN 'West'
        WHEN MAX(s.s_state) = 'NY' THEN 'East'
        ELSE 'Other'
      END AS region,
      MAX(i.total_inventory) AS total_inventory,
      MAX(ccd.cc_count) AS cc_count,
      MAX(ccd.max_tax) AS max_tax,
      MAX(wsd.site_count) AS site_count
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN inventory_daily i
      ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center_daily ccd
      ON ccd.date_sk = d.d_date_sk
    LEFT JOIN web_site_daily wsd
      ON wsd.date_sk = d.d_date_sk
    LEFT JOIN date_dim d_store_closed
      ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE
      d.d_year = 2001
      AND s.s_country = 'United States'
      AND ss.ss_ext_tax > 100
      AND i.total_inventory > 1000
      AND ccd.cc_count > 1
      AND wsd.site_count > 0
      AND d_store_closed.d_year >= 1999
      AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_mkt_desc LIKE '%dangerous%'
          AND cc.cc_open_date_sk = d.d_date_sk
      )
    GROUP BY ROLLUP (s.s_store_name, d.d_year)
  )
SELECT
  s_store_name,
  d_year,
  total_net_profit,
  total_sales,
  total_quantity,
  avg_tax,
  sales_transactions,
  region,
  total_inventory,
  cc_count,
  max_tax,
  site_count,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
  (
    SELECT AVG(sa2.total_net_profit)
    FROM (
      SELECT
        s2.s_store_name,
        d2.d_year,
        SUM(ss2.ss_net_profit) AS total_net_profit
      FROM store_sales ss2
      JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
      JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
      WHERE d2.d_year = sales_agg.d_year
      GROUP BY s2.s_store_name, d2.d_year
    ) sa2
  ) AS avg_yearly_profit
FROM sales_agg
WHERE s_store_name IS NOT NULL
  AND d_year IS NOT NULL
ORDER BY d_year, profit_rank
LIMIT 100
