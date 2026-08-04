WITH sales_agg AS (
   SELECT ss_sold_date_sk,
          SUM(ss_net_paid) AS total_net_paid,
          SUM(ss_net_profit) AS total_profit,
          COUNT(*) AS sales_cnt
   FROM store_sales
   WHERE ss_net_paid > 1000
     AND ss_quantity > 0
     AND ss_list_price < 20000
     AND ss_coupon_amt BETWEEN 100 AND 2000
     AND ss_ext_tax > 0
   GROUP BY ss_sold_date_sk
),
valid_return_dates AS (
   SELECT wr_returned_date_sk
   FROM web_returns
   WHERE wr_return_amt_inc_tax > 100
   EXCEPT
   SELECT wr_returned_date_sk
   FROM web_returns
   WHERE wr_return_amt_inc_tax > 5000
),
returns_filtered AS (
   SELECT *
   FROM web_returns wr
   WHERE wr.wr_returned_date_sk IN (SELECT wr_returned_date_sk FROM valid_return_dates)
     AND wr.wr_returning_cdemo_sk IN (SELECT ss_customer_sk FROM store_sales WHERE ss_quantity > 1)
     AND wr.wr_return_quantity > 0
     AND wr.wr_fee < 100
     AND wr.wr_return_tax > 0
),
joined_data AS (
   SELECT
       d.d_date_sk,
       d.d_year,
       d.d_quarter_name,
       d.d_current_quarter,
       s.total_net_paid,
       s.total_profit,
       s.sales_cnt,
       r.wr_return_amt_inc_tax,
       r.wr_net_loss
   FROM date_dim d
   JOIN sales_agg s ON s.ss_sold_date_sk = d.d_date_sk
   JOIN returns_filtered r ON r.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_current_quarter = 'Y'
     AND d.d_holiday = 'N'
     AND d.d_weekend = 'N'
     AND d.d_moy BETWEEN 1 AND 12
)
SELECT *
FROM (
   SELECT
       jd.d_year,
       jd.d_quarter_name,
       jd.total_net_paid,
       jd.total_profit,
       jd.sales_cnt,
       jd.wr_return_amt_inc_tax,
       jd.wr_net_loss,
       (SELECT SUM(ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = jd.d_date_sk) AS daily_ext_sales,
       ROW_NUMBER() OVER (PARTITION BY jd.d_year ORDER BY jd.total_net_paid DESC) AS rn
   FROM joined_data jd
   WHERE jd.total_net_paid > 0
     AND jd.sales_cnt >= 5
) final
WHERE rn <= 5
ORDER BY d_year, total_net_paid DESC
LIMIT 100
