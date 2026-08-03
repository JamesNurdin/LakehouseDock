WITH
  -- Aggregate sales at item‑date level
  sales_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit)      AS total_profit,
      COUNT(*)               AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451245   -- realistic date surrogate range
      AND ws_quantity > 1
      AND ws_ext_sales_price > 10
    GROUP BY ws_item_sk, ws_sold_date_sk
  ),
  -- Detail rows needed for later joins (warehouse, ship mode, time etc.)
  sales_detail AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_warehouse_sk,
      ws_web_site_sk,
      ws_ship_mode_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451245
  ),
  -- Bill‑customer link
  sales_customer AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_bill_customer_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2451245
  ),
  -- Filtered catalog pages
  catalog_page_f AS (
    SELECT cp_catalog_page_sk, cp_department, cp_start_date_sk, cp_end_date_sk
    FROM catalog_page
    WHERE cp_department IN ('Electronics', 'Books')
      AND cp_catalog_number BETWEEN 1 AND 5
  ),
  -- Filtered web returns
  web_returns_f AS (
    SELECT wr_order_number, wr_returned_date_sk, wr_return_amt, wr_return_quantity
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
  ),
  -- Full outer join between catalog pages and returns on the date key
  full_cp_wr AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cp.cp_start_date_sk,
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_return_amt
    FROM catalog_page_f cp
    FULL OUTER JOIN web_returns_f wr
      ON cp.cp_start_date_sk = wr.wr_returned_date_sk
  ),
  -- Union of two promotion‑channel selections (distinct by UNION)
  union_sales AS (
    SELECT
      sa.ws_item_sk,
      sa.ws_sold_date_sk,
      sa.total_sales,
      sa.total_profit,
      p.p_channel_email AS channel
    FROM sales_agg sa
    JOIN promotion p ON p.p_item_sk = sa.ws_item_sk
    WHERE p.p_channel_email = 'Y'
    UNION
    SELECT
      sa.ws_item_sk,
      sa.ws_sold_date_sk,
      sa.total_sales,
      sa.total_profit,
      p.p_channel_tv AS channel
    FROM sales_agg sa
    JOIN promotion p ON p.p_item_sk = sa.ws_item_sk
    WHERE p.p_channel_tv = 'Y'
  ),
  -- Main aggregation after all joins
  aggregated AS (
    SELECT
      d.d_year,
      i.i_category,
      ws.web_name               AS web_site_name,
      SUM(u.total_sales)        AS sum_sales,
      SUM(u.total_profit)       AS sum_profit,
      AVG(u.total_profit)       AS avg_profit,
      COUNT(DISTINCT u.ws_item_sk) AS distinct_items,
      cpwr.cp_department,
      cpwr.wr_return_amt,
      ca.ca_city,
      cd.cd_education_status,
      ib.ib_upper_bound,
      td.t_hour,
      sm.sm_type,
      w.w_warehouse_name
    FROM union_sales u
    JOIN date_dim d        ON u.ws_sold_date_sk = d.d_date_sk
    JOIN item i            ON u.ws_item_sk = i.i_item_sk
    RIGHT OUTER JOIN web_site ws
      ON d.d_date_sk = ws.web_open_date_sk
    LEFT JOIN full_cp_wr cpwr
      ON COALESCE(cpwr.cp_start_date_sk, cpwr.wr_returned_date_sk) = d.d_date_sk
    JOIN sales_detail sd   ON u.ws_item_sk = sd.ws_item_sk
                              AND u.ws_sold_date_sk = sd.ws_sold_date_sk
    JOIN time_dim td       ON sd.ws_sold_time_sk = td.t_time_sk
    JOIN sales_customer sc ON u.ws_item_sk = sc.ws_item_sk
                              AND u.ws_sold_date_sk = sc.ws_sold_date_sk
    JOIN customer c        ON sc.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib    ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm      ON sd.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w       ON sd.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY
      d.d_year,
      i.i_category,
      ws.web_name,
      cpwr.cp_department,
      cpwr.wr_return_amt,
      ca.ca_city,
      cd.cd_education_status,
      ib.ib_upper_bound,
      td.t_hour,
      sm.sm_type,
      w.w_warehouse_name
  )
SELECT
  a.d_year,
  a.i_category,
  a.web_site_name,
  a.sum_sales,
  a.avg_profit,
  a.distinct_items,
  CASE WHEN a.sum_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  (SELECT MAX(ib_upper_bound) FROM income_band WHERE ib_income_band_sk = 10) AS max_income_band_10,
  a.cp_department,
  a.wr_return_amt,
  a.ca_city,
  a.cd_education_status,
  a.ib_upper_bound,
  a.t_hour,
  a.sm_type,
  a.w_warehouse_name
FROM aggregated a
WHERE a.sum_sales > 1000                     -- filter 1
  AND a.distinct_items >= 5                 -- filter 2
  AND a.d_year BETWEEN 2000 AND 2002        -- filter 3
  AND a.i_category IN ('Electronics','Books') -- filter 4
  AND a.web_site_name IS NOT NULL           -- filter 5
  AND a.t_hour BETWEEN 9 AND 17             -- filter 6
  AND a.ca_city = 'Los Angeles'             -- extra realistic filter
  AND a.cd_education_status = 'College'
  AND a.sm_type = 'AIR'
ORDER BY a.sum_sales DESC
LIMIT 50
