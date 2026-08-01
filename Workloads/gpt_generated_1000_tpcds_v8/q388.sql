WITH
  catalog_agg AS (
    SELECT
      d.d_date_sk AS sales_date_sk,
      d.d_date    AS sales_date,
      sm.sm_ship_mode_id,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit)      AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY GROUPING SETS (
      (d.d_date_sk, d.d_date, sm.sm_ship_mode_id),
      (d.d_date_sk, d.d_date)
    )
  ),
  store_agg AS (
    SELECT
      d.d_date_sk AS sales_date_sk,
      d.d_date    AS sales_date,
      'STORE'      AS source,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit)      AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 15000 THEN 'High' ELSE 'Low' END AS profit_category,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
  ),
  common_dates AS (
    SELECT sales_date_sk FROM catalog_agg
    INTERSECT
    SELECT sales_date_sk FROM store_agg
  )
SELECT DISTINCT
  COALESCE(ca.sales_date, sa.sales_date)                               AS sales_date,
  COALESCE(ca.sm_ship_mode_id, 'N/A')                                   AS ship_mode,
  ca.total_sales                                                       AS catalog_sales,
  sa.total_sales                                                       AS store_sales,
  CASE
    WHEN ca.profit_category = 'High' OR sa.profit_category = 'High' THEN 'High Overall'
    ELSE 'Low Overall'
  END                                                                   AS overall_profit_category,
  ca.distinct_orders                                                   AS catalog_distinct_orders,
  sa.distinct_tickets                                                  AS store_distinct_tickets,
  (SELECT SUM(wr.wr_return_amt)
     FROM web_returns wr
    WHERE wr.wr_returned_date_sk = COALESCE(ca.sales_date_sk, sa.sales_date_sk)) AS total_return_amount_for_day
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
  ON ca.sales_date_sk = sa.sales_date_sk
WHERE COALESCE(ca.sales_date_sk, sa.sales_date_sk) IN (SELECT sales_date_sk FROM common_dates)
ORDER BY sales_date DESC, ship_mode
