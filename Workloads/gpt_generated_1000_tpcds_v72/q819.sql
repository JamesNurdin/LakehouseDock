WITH
  filtered_stores AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      CONCAT(s.s_city, ', ', s.s_state) AS city_state,
      s.s_gmt_offset
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(s.s_store_name, '^A.*')
  ),
  top_items AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk
    UNION ALL
    SELECT ss.ss_item_sk AS item_sk,
           SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
    GROUP BY ss.ss_item_sk
  )
SELECT
  fs.s_store_name,
  fs.city_state,
  d.d_year,
  ca.ca_city,
  ca.ca_zip,
  regexp_extract(ca.ca_zip, '^([0-9]{3})', 1) AS zip_prefix,
  SUM(ss.ss_net_profit) AS store_net_profit,
  (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ) AS avg_yearly_profit
FROM store_sales ss
JOIN filtered_stores fs ON ss.ss_store_sk = fs.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN top_items ti ON ss.ss_item_sk = ti.item_sk
WHERE d.d_year = 2001
  AND ca.ca_street_name LIKE '%Hill%'
  AND regexp_like(ca.ca_street_name, 'Hill')
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = ss.ss_item_sk
          AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
      )
GROUP BY
  fs.s_store_name,
  fs.city_state,
  d.d_year,
  ca.ca_city,
  ca.ca_zip,
  regexp_extract(ca.ca_zip, '^([0-9]{3})', 1)
ORDER BY store_net_profit DESC
LIMIT 100
