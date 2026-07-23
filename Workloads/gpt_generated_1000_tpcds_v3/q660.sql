WITH base AS (
   SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      d.d_year,
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      ss.ss_net_profit,
      ss.ss_quantity,
      c.c_customer_sk,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      ca.ca_city,
      t.t_hour
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE
      d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 8 AND 12
      AND ib.ib_upper_bound > 50000
      AND ca.ca_country = 'United States'
      AND EXISTS (
         SELECT 1
         FROM catalog_returns cr
         JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
         JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
         WHERE cr.cr_item_sk = ss.ss_item_sk
           AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
           AND sm.sm_type = 'AIR'
           AND r.r_reason_desc = 'Customer Not Satisfied'
      )
      AND EXISTS (
         SELECT 1
         FROM web_sales ws
         JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
         WHERE ws.ws_item_sk = ss.ss_item_sk
           AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
           AND w.web_manager = 'Moses Hicks'
      )
      AND EXISTS (
         SELECT 1
         FROM call_center cc
         WHERE cc.cc_closed_date_sk = d.d_date_sk
           AND cc.cc_state = 'CA'
      )
),
agg AS (
   SELECT
      s_store_sk,
      s_store_name,
      d_year,
      i_brand,
      i_category,
      SUM(ss_net_profit) AS total_profit,
      SUM(ss_quantity) AS total_quantity,
      AVG(ss_net_profit) AS avg_profit_per_quantity
   FROM base
   GROUP BY s_store_sk, s_store_name, d_year, i_brand, i_category
   HAVING SUM(ss_net_profit) > 10000
)
SELECT
   s_store_sk,
   s_store_name,
   d_year,
   i_brand,
   i_category,
   total_profit,
   total_quantity,
   avg_profit_per_quantity,
   DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
