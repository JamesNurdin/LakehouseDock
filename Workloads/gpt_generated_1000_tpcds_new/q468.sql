WITH
  base AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      d.d_year,
      i.i_category,
      i.i_manufact_id,
      wr.wr_return_amt,
      wr.wr_net_loss,
      ws.web_city,
      ws.web_tax_percentage,
      CASE WHEN ws.web_tax_percentage > 0.05 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_level
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND ws.web_city IN ('Mount Pleasant', 'Salem')
      AND ws.web_tax_percentage BETWEEN 0.02 AND 0.07
      AND wr.wr_return_amt > 100
  ),
  agg1 AS (
    SELECT
      d_year,
      i_category,
      tax_level,
      MIN(wr_order_number) AS rep_order_number,
      SUM(wr_return_amt) AS sum_return_amt,
      AVG(wr_net_loss) AS avg_net_loss,
      COUNT(DISTINCT wr_order_number) AS orders_cnt
    FROM base
    GROUP BY d_year, i_category, tax_level
  ),
  site_agg AS (
    SELECT
      ws.web_city,
      SUM(wr.wr_return_amt) AS city_return_amt,
      COUNT(*) AS city_return_cnt
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.web_city
  ),
  except_orders AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt > 500
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt > 2000
  )
SELECT
  COALESCE(a.d_year, -1)               AS year,
  COALESCE(a.i_category, 'UNKNOWN')   AS category,
  COALESCE(a.tax_level, 'UNKNOWN')    AS tax_level,
  a.sum_return_amt,
  a.avg_net_loss,
  a.orders_cnt,
  s.web_city,
  s.city_return_amt,
  s.city_return_cnt
FROM agg1 a
FULL OUTER JOIN site_agg s
  ON a.tax_level = CASE WHEN s.city_return_amt > 2000 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END
LEFT JOIN except_orders eo
  ON eo.wr_order_number = a.rep_order_number
WHERE eo.wr_order_number IS NULL
  AND a.sum_return_amt > (
        SELECT AVG(wr_return_amt)
        FROM web_returns
        WHERE wr_return_amt > 0
      )
ORDER BY a.sum_return_amt DESC
OFFSET 10
LIMIT 100
