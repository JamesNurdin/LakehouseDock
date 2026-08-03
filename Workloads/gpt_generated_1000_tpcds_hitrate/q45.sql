WITH
  returns_agg AS (
    SELECT
      s.s_city AS city,
      d.d_year AS year,
      SUM(sr.sr_net_loss) AS metric,
      CAST('returns' AS varchar) AS source
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_city IN ('Friendship', 'Harmony')
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
      (s.s_city, d.d_year),
      (s.s_city),
      (d.d_year)
    )
  ),
  inventory_agg AS (
    SELECT
      s.s_city AS city,
      d.d_year AS year,
      SUM(inv.inv_quantity_on_hand * i.i_current_price) AS metric,
      CAST('inventory' AS varchar) AS source
    FROM inventory inv
    JOIN item i
      ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d
      ON inv.inv_date_sk = d.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE i.i_brand = 'Brand#12'
      AND d.d_year = 2001
    GROUP BY GROUPING SETS (
      (s.s_city, d.d_year),
      (s.s_city),
      (d.d_year)
    )
  )
SELECT city,
       year,
       metric,
       source
FROM returns_agg
UNION ALL
SELECT city,
       year,
       metric,
       source
FROM inventory_agg
ORDER BY city,
         year DESC,
         source
LIMIT 100
