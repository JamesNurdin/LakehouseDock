WITH base AS (
   SELECT
       d.d_year,
       d.d_qoy,
       hd.hd_demo_sk,
       hd.hd_vehicle_count,
       p.p_promo_name,
       p.p_discount_active,
       inv.inv_quantity_on_hand,
       ss.ss_quantity,
       ss.ss_net_paid_inc_tax,
       ss.ss_net_profit,
       wr.wr_return_amt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_qoy = 2
     AND hd.hd_vehicle_count >= 2
     AND p.p_discount_active = 'Y'
     AND inv.inv_quantity_on_hand > 500
),
agg AS (
   SELECT
       d_year,
       hd_demo_sk,
       p_promo_name,
       SUM(ss_net_paid_inc_tax) AS total_sales,
       SUM(wr_return_amt) AS total_returns,
       COUNT(DISTINCT ss_quantity) AS distinct_quantity_cnt,
       CASE WHEN SUM(ss_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
   FROM base
   GROUP BY d_year, hd_demo_sk, p_promo_name
   HAVING SUM(ss_net_paid_inc_tax) > 10000
)
SELECT
   DISTINCT d_year,
   hd_demo_sk,
   p_promo_name,
   total_sales,
   total_returns,
   distinct_quantity_cnt,
   profit_category,
   RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
   SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM agg
ORDER BY d_year, total_sales DESC
