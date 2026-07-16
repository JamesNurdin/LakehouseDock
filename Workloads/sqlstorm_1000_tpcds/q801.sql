WITH all_sales AS (
   SELECT ss.ss_sold_date_sk AS sold_date_sk,
          ss.ss_store_sk AS store_sk,
          NULL AS catalog_page_sk,
          NULL AS web_page_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_promo_sk AS promo_sk,
          ss.ss_net_paid AS net_paid,
          ss.ss_ext_discount_amt AS discount_amt,
          ss.ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT cs.cs_sold_date_sk,
          NULL,
          cs.cs_catalog_page_sk,
          NULL,
          cs.cs_bill_customer_sk,
          cs.cs_item_sk,
          cs.cs_promo_sk,
          cs.cs_net_paid,
          cs.cs_ext_discount_amt,
          cs.cs_net_profit,
          'catalog'
   FROM catalog_sales cs
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          NULL,
          NULL,
          ws.ws_web_page_sk,
          ws.ws_bill_customer_sk,
          ws.ws_item_sk,
          ws.ws_promo_sk,
          ws.ws_net_paid,
          ws.ws_ext_discount_amt,
          ws.ws_net_profit,
          'web'
   FROM web_sales ws
),
sales_agg AS (
   SELECT d.d_year,
          d.d_moy AS month,
          a.channel,
          sum(a.net_paid) AS total_net_paid,
          sum(a.discount_amt) AS total_discount,
          sum(a.net_profit) AS total_profit,
          count(DISTINCT a.customer_sk) AS distinct_customers
   FROM all_sales a
   JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
   GROUP BY d.d_year, d.d_moy, a.channel
)
SELECT s.d_year,
       s.month,
       s.channel,
       s.total_net_paid,
       s.total_discount,
       s.total_profit,
       s.distinct_customers,
       rank() OVER (PARTITION BY s.d_year, s.channel ORDER BY s.total_net_paid DESC) AS sales_rank
FROM sales_agg s
ORDER BY s.d_year, s.channel, sales_rank
