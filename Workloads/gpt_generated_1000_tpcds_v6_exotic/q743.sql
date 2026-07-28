WITH joined_data AS (
   SELECT
       d.d_fy_year,
       i.i_manufact,
       ib.ib_income_band_sk,
       cs.cs_ext_sales_price   AS cs_sales,
       ss.ss_ext_sales_price   AS ss_sales,
       cs.cs_net_profit        AS cs_profit,
       ss.ss_net_profit        AS ss_profit,
       cs.cs_order_number,
       ss.ss_ticket_number,
       hd.hd_dep_count,
       hd.hd_vehicle_count
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN store_sales ss
     ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_fy_year BETWEEN 1908 AND 1916
     AND i.i_current_price > 1.00
     AND hd.hd_dep_count >= 2
     AND hd.hd_vehicle_count >= 0
     AND i.i_manufact LIKE '%bar%'
),
agg AS (
   SELECT
       d_fy_year,
       i_manufact,
       ib_income_band_sk,
       SUM(cs_sales)                         AS catalog_sales_total,
       SUM(ss_sales)                         AS store_sales_total,
       SUM(cs_profit) + SUM(ss_profit)       AS total_profit,
       COUNT(DISTINCT cs_order_number)       AS catalog_orders,
       COUNT(DISTINCT ss_ticket_number)      AS store_tickets,
       AVG(hd_dep_count)                    AS avg_dep_count,
       AVG(hd_vehicle_count)                AS avg_vehicle_count
   FROM joined_data
   GROUP BY d_fy_year, i_manufact, ib_income_band_sk
)
SELECT
    i_manufact,
    d_fy_year,
    ib_income_band_sk,
    total_profit,
    catalog_sales_total,
    store_sales_total,
    AVG(total_profit) OVER (PARTITION BY i_manufact)                           AS avg_profit_per_manufact,
    SUM(total_profit) OVER (PARTITION BY i_manufact ORDER BY d_fy_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)                     AS cumulative_profit,
    RANK() OVER (PARTITION BY i_manufact ORDER BY total_profit DESC)          AS profit_rank,
    avg_dep_count,
    avg_vehicle_count
FROM agg
WHERE catalog_sales_total > 0
  AND store_sales_total > 0
  AND avg_dep_count > 1
  AND avg_vehicle_count >= 0
  AND total_profit > 1000
ORDER BY cumulative_profit DESC
LIMIT 100
