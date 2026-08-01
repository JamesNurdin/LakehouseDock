WITH
  sales_per_store AS (
    SELECT s.s_store_sk,
           d.d_year,
           SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_sk, d.d_year
  ),
  returns_per_store AS (
    SELECT s.s_store_sk,
           d.d_year,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_sk, d.d_year
  ),
  sales_join AS (
    SELECT COALESCE(sps.s_store_sk, rps.s_store_sk) AS store_sk,
           COALESCE(sps.d_year, rps.d_year) AS d_year,
           sps.total_net_paid,
           rps.total_net_loss
    FROM sales_per_store sps
    FULL OUTER JOIN returns_per_store rps
      ON sps.s_store_sk = rps.s_store_sk AND sps.d_year = rps.d_year
  ),
  high_sales AS (
    SELECT store_sk,
           d_year,
           (COALESCE(total_net_paid, 0) - COALESCE(total_net_loss, 0)) AS net_metric
    FROM sales_join
    WHERE COALESCE(total_net_paid, 0) > COALESCE(total_net_loss, 0)
  ),
  inventory_sales AS (
    SELECT i.i_item_sk AS store_sk,
           d.d_year,
           SUM(inv.inv_quantity_on_hand) AS net_metric
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_sk, d.d_year
  ),
  blacklist AS (
    SELECT s.s_store_sk AS store_sk, d.d_year
    FROM store s
    JOIN date_dim d ON 1 = 1
    WHERE s.s_geography_class = 'Unknown'
  ),
  year2001_stores AS (
    SELECT s_store_sk AS store_sk, d_year
    FROM sales_per_store
    WHERE d_year = 2001
  ),
  unioned AS (
    SELECT store_sk, d_year, net_metric FROM high_sales
    UNION
    SELECT store_sk, d_year, net_metric FROM inventory_sales
  ),
  set_excluded AS (
    SELECT store_sk, d_year, net_metric
    FROM unioned
    EXCEPT
    SELECT u.store_sk, u.d_year, u.net_metric
    FROM unioned u
    JOIN blacklist b ON u.store_sk = b.store_sk AND u.d_year = b.d_year
  ),
  final_set AS (
    SELECT store_sk, d_year, net_metric
    FROM set_excluded
    INTERSECT
    SELECT u.store_sk, u.d_year, u.net_metric
    FROM unioned u
    JOIN year2001_stores y ON u.store_sk = y.store_sk AND u.d_year = y.d_year
  )
SELECT f.store_sk,
       f.d_year,
       f.net_metric,
       ROW_NUMBER() OVER (PARTITION BY f.store_sk ORDER BY f.net_metric DESC) AS rank_in_store
FROM final_set f
ORDER BY f.net_metric DESC, f.store_sk
LIMIT 100
