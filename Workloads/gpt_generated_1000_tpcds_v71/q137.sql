WITH
  sales_cte AS (
    SELECT
      d.d_year AS sales_year,
      wsite.web_name,
      SUM(ws.ws_net_paid) AS total_sales,
      AVG(ib.ib_upper_bound) AS avg_income_upper
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND wsite.web_city = 'Lakewood'
      AND wsite.web_street_type = 'Road'
      AND ib.ib_upper_bound > 50000
      AND wsite.web_state = 'CA'                -- extra predicate on web_site (allowed column)
      AND d.d_current_month = 'Y'
    GROUP BY d.d_year, wsite.web_name
  ),
  returns_cte AS (
    SELECT
      d.d_year AS sales_year,
      s.s_store_name,
      SUM(sr.sr_refunded_cash) AS total_returns,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '>10000'
      AND r.r_reason_desc LIKE '%damaged%'
      AND s.s_number_employees > 50
    GROUP BY d.d_year, s.s_store_name
  ),
  inventory_cte AS (
    SELECT
      d.d_year AS sales_year,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_current_month = 'Y'
      AND d.d_holiday = 'N'
    GROUP BY d.d_year
  )
SELECT
  s.sales_year,
  s.web_name,
  r.s_store_name,
  s.total_sales,
  r.total_returns,
  i.total_inventory,
  (s.total_sales - r.total_returns) AS net_sales,
  (s.total_sales - r.total_returns) / NULLIF(i.total_inventory, 0) AS sales_per_inventory
FROM sales_cte s
JOIN returns_cte r ON s.sales_year = r.sales_year
JOIN inventory_cte i ON s.sales_year = i.sales_year
WHERE (s.total_sales - r.total_returns) > 100000
ORDER BY net_sales DESC
LIMIT 100
