WITH
  ss_base AS (
    SELECT
      ss.ss_sold_date_sk AS d_date_sk,
      ss.ss_sold_time_sk AS t_time_sk,
      ss.ss_item_sk AS i_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  ),
  cs_base AS (
    SELECT
      cs.cs_sold_date_sk AS d_date_sk,
      cs.cs_sold_time_sk AS t_time_sk,
      cs.cs_item_sk AS i_item_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_mode_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  common_items AS (
    SELECT i_item_sk FROM ss_base
    INTERSECT
    SELECT i_item_sk FROM cs_base
  ),
  joined AS (
    SELECT
      COALESCE(ss.d_date_sk, cs.d_date_sk) AS d_date_sk,
      COALESCE(ss.t_time_sk, cs.t_time_sk) AS t_time_sk,
      COALESCE(ss.i_item_sk, cs.i_item_sk) AS i_item_sk,
      ss.ss_quantity,
      cs.cs_quantity AS cs_quantity,
      ss.ss_ext_sales_price,
      cs.cs_ext_sales_price AS cs_ext_sales_price,
      ss.ss_net_profit,
      cs.cs_net_profit AS cs_net_profit
    FROM ss_base ss
    FULL OUTER JOIN cs_base cs
      ON ss.d_date_sk = cs.d_date_sk
     AND ss.t_time_sk = cs.t_time_sk
     AND ss.i_item_sk = cs.i_item_sk
  ),
  agg AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      j.i_item_sk,
      SUM(COALESCE(j.ss_ext_sales_price,0) + COALESCE(j.cs_ext_sales_price,0)) AS total_sales,
      COUNT(DISTINCT j.i_item_sk) AS distinct_items_sold,
      AVG(COALESCE(j.ss_net_profit,0) + COALESCE(j.cs_net_profit,0)) AS avg_profit,
      MAX(COALESCE(j.ss_ext_sales_price,0)) AS max_store_sales_price,
      MIN(COALESCE(j.cs_ext_sales_price,0)) AS min_catalog_sales_price,
      wp_stats.page_visits
    FROM joined j
    JOIN date_dim d ON j.d_date_sk = d.d_date_sk
    JOIN item i ON j.i_item_sk = i.i_item_sk
    JOIN LATERAL (
      SELECT COUNT(*) AS page_visits
      FROM web_page wp
      WHERE wp.wp_creation_date_sk = d.d_date_sk
    ) wp_stats ON TRUE
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
      AND i.i_size IN ('M','L')
      AND i.i_current_price BETWEEN 100 AND 500
      AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_income_band_sk = 3
      )
      AND j.i_item_sk IN (SELECT i_item_sk FROM common_items)
    GROUP BY d.d_year, i.i_category, i.i_brand, j.i_item_sk, wp_stats.page_visits
  )
SELECT
  a.d_year,
  a.i_category,
  a.i_brand,
  a.total_sales,
  a.distinct_items_sold,
  a.avg_profit,
  a.max_store_sales_price,
  a.min_catalog_sales_price,
  a.page_visits,
  LAG(a.total_sales) OVER (PARTITION BY a.i_brand ORDER BY a.d_year) AS lag_total_sales,
  (
    SELECT AVG(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = a.i_item_sk
  ) AS avg_item_catalog_price
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
