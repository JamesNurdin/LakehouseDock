WITH customer_sales AS (
   SELECT
       c.c_customer_sk,
       c.c_current_hdemo_sk,
       hd.hd_income_band_sk,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
       SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_qty_sales
   FROM
       tpcds.customer c
       JOIN tpcds.store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
       JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE
       ss.ss_quantity BETWEEN 1 AND 10
       AND ss.ss_sales_price > 10
       AND hd.hd_vehicle_count >= 0
       AND hd.hd_buy_potential IS NOT NULL
       AND c.c_preferred_cust_flag = 'Y'
       AND c.c_birth_year BETWEEN 1950 AND 1990
   GROUP BY
       c.c_customer_sk,
       c.c_current_hdemo_sk,
       hd.hd_income_band_sk
),
web_activity AS (
   SELECT
       c.c_customer_sk,
       hd.hd_income_band_sk,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_net_loss) AS total_net_loss,
       COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
       AVG(wp.wp_image_count) AS avg_image_count
   FROM
       tpcds.customer c
       JOIN tpcds.web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
       JOIN tpcds.household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
       JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE
       wr.wr_return_quantity > 0
       AND wr.wr_return_amt > 5
       AND wp.wp_image_count <= 5
       AND wp.wp_link_count >= 8
       AND wp.wp_rec_start_date >= DATE '2001-01-01'
       AND wp.wp_type = 'content'
   GROUP BY
       c.c_customer_sk,
       hd.hd_income_band_sk
)
SELECT
   cs.c_current_hdemo_sk AS demo_sk,
   cs.hd_income_band_sk,
   SUM(cs.total_sales) AS agg_sales,
   AVG(cs.total_profit) AS avg_profit,
   SUM(wa.total_return_amt) AS agg_returns,
   AVG(wa.total_net_loss) AS avg_net_loss,
   COUNT(DISTINCT cs.c_customer_sk) AS customer_cnt
FROM
   customer_sales cs
   LEFT JOIN web_activity wa ON cs.c_customer_sk = wa.c_customer_sk
       AND cs.hd_income_band_sk = wa.hd_income_band_sk
WHERE
   cs.total_sales > 1000
   AND cs.total_profit > 0
   AND (wa.total_return_amt IS NULL OR wa.total_return_amt < 5000)
   AND cs.high_qty_sales > 0
   AND cs.distinct_tickets >= 1
   AND cs.c_current_hdemo_sk IS NOT NULL
GROUP BY
   cs.c_current_hdemo_sk,
   cs.hd_income_band_sk
ORDER BY
   agg_sales DESC
LIMIT 100
