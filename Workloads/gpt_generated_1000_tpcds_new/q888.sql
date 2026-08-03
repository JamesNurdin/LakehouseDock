/*
Goal: Compute total store and catalog profit per web site and call center for the year 2001, restricted to male customers in high‑income households, TV‑promoted items that also appear in catalog promotions, and orders that were not returned. Rank the results by store profit and limit to the top 100 rows.
*/
WITH
  /* Sample a fraction of catalog sales */
  cs_sample AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 0
  ),
  /* Order numbers that have a return */
  returned_orders AS (
    SELECT cr.cr_order_number AS order_num
    FROM tpcds.catalog_returns cr
  ),
  /* Orders that were sold but never returned */
  non_returned_orders AS (
    SELECT cs.cs_order_number AS order_num
    FROM cs_sample cs
    EXCEPT
    SELECT order_num FROM returned_orders
  ),
  /* Promotions that run on TV */
  tv_promos AS (
    SELECT p.p_promo_sk AS promo_sk
    FROM tpcds.promotion p
    WHERE p.p_channel_tv = 'Y'
  ),
  /* Promotions that run in the catalog */
  catalog_promos AS (
    SELECT p.p_promo_sk AS promo_sk
    FROM tpcds.promotion p
    WHERE p.p_channel_catalog = 'Y'
  ),
  /* Promotions that are both TV and catalog */
  common_promos AS (
    SELECT promo_sk FROM tv_promos
    INTERSECT
    SELECT promo_sk FROM catalog_promos
  ),
  /* Aggregate profit information */
  sales_agg AS (
    SELECT
      ws.web_name,
      cc.cc_name,
      d_year,
      SUM(ss.ss_net_profit)               AS store_profit,
      SUM(cs.cs_net_profit)               AS catalog_profit,
      COUNT(DISTINCT cs.cs_order_number)  AS order_cnt,
      SUM(cr.cr_net_loss)                 AS total_return_loss
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d1               ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN tpcds.customer c                ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp               ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site ws               ON ws.web_open_date_sk = d1.d_date_sk
    JOIN tpcds.call_center cc            ON cc.cc_open_date_sk = d1.d_date_sk
    JOIN cs_sample cs                    ON cs.cs_bill_customer_sk = c.c_customer_sk
                                           AND cs.cs_sold_date_sk = d1.d_date_sk
    JOIN tpcds.catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN tpcds.catalog_returns cr   ON cr.cr_order_number = cs.cs_order_number
    JOIN common_promos cpmt               ON p.p_promo_sk = cpmt.promo_sk
    WHERE d1.d_year = 2001
      AND p.p_channel_tv = 'Y'
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 50000
      AND wp.wp_image_count >= 5
      AND cc.cc_state = 'CA'
      AND EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_image_count > 5
      )
      AND cs.cs_order_number IN (SELECT order_num FROM non_returned_orders)
    GROUP BY ws.web_name, cc.cc_name, d_year
  )
SELECT
  web_name,
  cc_name,
  d_year,
  store_profit,
  catalog_profit,
  order_cnt,
  total_return_loss,
  RANK() OVER (ORDER BY store_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
