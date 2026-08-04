WITH distinct_reason AS (
   SELECT DISTINCT r_reason_sk, r_reason_desc
   FROM reason
),
sampled_ws AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
)
SELECT
   cp.cp_catalog_page_id,
   i.i_item_id,
   i.i_current_price,
   ib.ib_upper_bound,
   t.t_hour,
   dr.r_reason_desc,
   wsite.web_name,
   ws.ws_net_profit,
   ROW_NUMBER() OVER (PARTITION BY wsite.web_site_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
   CASE
      WHEN i.i_current_price > (
         SELECT MAX(i_cur_price)
         FROM (
            SELECT i_current_price AS i_cur_price
            FROM item
            WHERE i_brand = 'Brand1'
         ) sub
      ) THEN 1
      ELSE 0
   END AS price_above_max_brand1,
   COUNT(*) OVER (PARTITION BY wsite.web_site_id) AS orders_per_site
FROM catalog_page cp
JOIN catalog_returns cr
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN distinct_reason dr
  ON cr.cr_reason_sk = dr.r_reason_sk
JOIN store_returns sr
  ON sr.sr_reason_sk = dr.r_reason_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
JOIN sampled_ws ws
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
 AND wr.wr_order_number = ws.ws_order_number
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE i.i_current_price > 50
  AND ib.ib_upper_bound >= 100000
  AND t.t_hour BETWEEN 9 AND 17
  AND dr.r_reason_desc = 'Customer Not Satisfied'
  AND wsite.web_country = 'United States'
  AND ws.ws_ext_tax > 20
  AND ws.ws_sold_date_sk = (
      SELECT MIN(cr_returned_date_sk)
      FROM catalog_returns
   )
ORDER BY profit_rank ASC, i.i_current_price DESC
LIMIT 100
