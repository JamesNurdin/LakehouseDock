WITH base AS (
   SELECT
      d.d_year,
      s.s_store_name,
      cs.cs_net_paid_inc_tax,
      cs.cs_ext_tax,
      ss.ss_net_paid_inc_tax,
      ss.ss_net_profit,
      wp.wp_url,
      wp.wp_type,
      d.d_holiday
   FROM date_dim d
   JOIN catalog_sales cs
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN store_sales ss
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d_ship
     ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN date_dim d_closed
     ON s.s_closed_date_sk = d_closed.d_date_sk
   JOIN date_dim d_sold2
     ON cs.cs_sold_date_sk = d_sold2.d_date_sk
   JOIN date_dim d_closed2
     ON s.s_closed_date_sk = d_closed2.d_date_sk
   JOIN web_page wp
     ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN date_dim d_access
     ON wp.wp_access_date_sk = d_access.d_date_sk
   WHERE d.d_holiday = 'N'
),
agg AS (
   SELECT
      s_store_name,
      d_year,
      SUM(cs_net_paid_inc_tax) AS sum_cs_net_paid,
      SUM(ss_net_paid_inc_tax) AS sum_ss_net_paid,
      SUM(cs_ext_tax) AS sum_ext_tax,
      COUNT(*) AS txn_count
   FROM base
   GROUP BY GROUPING SETS ((s_store_name, d_year), (s_store_name), (d_year))
)
SELECT
   s_store_name,
   d_year,
   sum_cs_net_paid,
   sum_ss_net_paid,
   sum_ext_tax,
   txn_count,
   (SELECT MAX(cs_net_paid_inc_tax) FROM catalog_sales) AS max_catalog_net_paid,
   ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY (sum_cs_net_paid + sum_ss_net_paid) DESC) AS rn
FROM agg
ORDER BY (sum_cs_net_paid + sum_ss_net_paid) DESC
LIMIT 100
