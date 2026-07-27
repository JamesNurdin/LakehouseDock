WITH
  sales_agg AS (
    SELECT
      ss_store_sk,
      ss_sold_date_sk,
      MIN(ss_addr_sk) AS addr_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_profit,
      SUM(ss_quantity) AS total_qty
    FROM store_sales
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY ss_store_sk, ss_sold_date_sk
  ),
  returns_agg AS (
    SELECT
      sr_store_sk,
      sr_returned_date_sk,
      COUNT(*) AS return_cnt,
      SUM(sr_refunded_cash) AS refunded_cash
    FROM store_returns
    WHERE sr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY sr_store_sk, sr_returned_date_sk
  ),
  avg_profit AS (
    SELECT
      d.d_year,
      AVG(sa.total_profit) AS avg_profit
    FROM sales_agg sa
    JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
  )
SELECT
  s.s_store_id,
  s.s_store_name,
  d_sales.d_month_seq,
  d_sales.d_year,
  ca.ca_city,
  ca.ca_street_type,
  s.s_state,
  sa.total_sales,
  sa.total_profit,
  CASE WHEN sa.total_profit > ap.avg_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
  COALESCE(ra.return_cnt, 0) AS return_count,
  RANK() OVER (PARTITION BY d_sales.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d_sales.d_date_sk) AS sales_day_seq
FROM sales_agg sa
JOIN store s
  ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
  ON sa.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN returns_agg ra
  ON s.s_store_sk = ra.sr_store_sk
  AND d_sales.d_date_sk = ra.sr_returned_date_sk
JOIN customer_address ca
  ON sa.addr_sk = ca.ca_address_sk
JOIN time_dim t_sales
  ON EXISTS (
       SELECT 1
       FROM store_sales ssx
       WHERE ssx.ss_store_sk = s.s_store_sk
         AND ssx.ss_sold_date_sk = d_sales.d_date_sk
         AND ssx.ss_sold_time_sk = t_sales.t_time_sk
         AND t_sales.t_hour BETWEEN 9 AND 17
     )
JOIN date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
     AND d_closed.d_year = 2001
JOIN avg_profit ap
  ON d_sales.d_year = ap.d_year
WHERE
  d_sales.d_year = 2001
  AND s.s_state = 'CA'
  AND ca.ca_city = 'Glendale'
  AND ca.ca_street_type = 'Court'
  AND t_sales.t_am_pm = 'PM'
