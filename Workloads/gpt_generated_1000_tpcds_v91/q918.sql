WITH base AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_customer_sk AS customer_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_sales_price,
      d_sales.d_year,
      d_sales.d_month_seq,
      t.t_hour,
      i.i_item_id,
      i.i_item_desc,
      i.i_current_price,
      i.i_category,
      i.i_class,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      cd.cd_marital_status,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      split(i.i_item_desc, ' ') AS desc_words
   FROM store_sales ss
   JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
   WHERE d_sales.d_year = 2002
     AND i.i_current_price > 20
     AND ib.ib_lower_bound >= 80001
     AND t.t_hour BETWEEN 12 AND 14
     AND ss.ss_sales_price > 50
),
unnested AS (
   SELECT
      b.*, 
      w.desc_word
   FROM base b
   CROSS JOIN UNNEST(b.desc_words) AS w(desc_word)
   WHERE NOT EXISTS (
      SELECT 1
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      WHERE ss2.ss_customer_sk = b.customer_sk
        AND i2.i_category = 'Electronics'
   )
),
agg AS (
   SELECT
      d_year,
      i_category,
      hd_buy_potential,
      COUNT(DISTINCT ss_ticket_number) AS orders,
      SUM(ss_ext_sales_price) AS total_sales,
      AVG(ss_net_profit) AS avg_profit,
      MIN(ss_ext_sales_price) AS min_sale,
      MAX(ss_ext_sales_price) AS max_sale,
      COUNT(DISTINCT desc_word) AS distinct_desc_words
   FROM unnested
   GROUP BY d_year, i_category, hd_buy_potential
)
SELECT
   d_year,
   i_category,
   hd_buy_potential,
   orders,
   total_sales,
   avg_profit,
   min_sale,
   max_sale,
   distinct_desc_words,
   SUM(total_sales) OVER (PARTITION BY i_category ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_category,
   RANK() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
