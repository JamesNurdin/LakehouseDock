WITH sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_county,
    cp.cp_type,
    ib.ib_income_band_sk,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
  FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE
    d.d_year = 2001
    AND s.s_county = 'Jackson County'
    AND cp.cp_type = 'monthly'
    AND ib.ib_upper_bound > 50000
    AND EXISTS (
      SELECT 1
      FROM web_returns wr
      JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
      WHERE wr.wr_item_sk = ss.ss_item_sk
        AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    )
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_county,
    cp.cp_type,
    ib.ib_income_band_sk
)
SELECT
  s_store_name,
  s_county,
  cp_type,
  ib_income_band_sk,
  total_profit,
  order_cnt,
  total_profit / order_cnt AS avg_profit_per_order
FROM
  sales_agg
WHERE
  total_profit / order_cnt > 100
ORDER BY
  avg_profit_per_order DESC
LIMIT 100
