WITH sales_full AS (
   SELECT
     d.d_year,
     hd.hd_buy_potential,
     cs.cs_net_paid
   FROM catalog_sales cs
   FULL OUTER JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   -- keep rows from both sides; no filter that would remove unmatched rows
)
SELECT d_year, hd_buy_potential
FROM (
   SELECT d_year, hd_buy_potential
   FROM sales_full
   WHERE cs_net_paid > 1000
   GROUP BY CUBE(d_year, hd_buy_potential)
) AS high
INTERSECT
SELECT d_year, hd_buy_potential
FROM (
   SELECT d_year, hd_buy_potential
   FROM sales_full
   WHERE cs_net_paid < 500
   GROUP BY CUBE(d_year, hd_buy_potential)
) AS low
ORDER BY d_year NULLS LAST, hd_buy_potential
LIMIT 100
