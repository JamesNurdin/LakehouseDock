WITH sales_combined AS (
   SELECT cs.cs_sold_date_sk AS sold_date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_call_center_sk AS call_center_sk,
          cs.cs_promo_sk AS promo_sk,
          cs.cs_quantity AS quantity,
          cs.cs_net_paid AS net_paid,
          'catalog' AS sales_channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_bill_customer_sk,
          NULL,
          ws.ws_promo_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          'web'
   FROM web_sales ws
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_customer_sk,
          NULL,
          ss.ss_promo_sk,
          ss.ss_quantity,
          ss.ss_net_paid,
          'store'
   FROM store_sales ss
),
joined_sales AS (
   SELECT sc.sold_date_sk,
          d.d_year,
          i.i_category,
          i.i_brand,
          ca.ca_state,
          cd.cd_gender,
          p.p_discount_active AS promo_active,
          sc.sales_channel,
          sc.quantity,
          sc.net_paid,
          c.c_customer_sk
   FROM sales_combined sc
   JOIN date_dim d ON sc.sold_date_sk = d.d_date_sk
   JOIN item i ON sc.item_sk = i.i_item_sk
   LEFT JOIN customer c ON sc.customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON sc.promo_sk = p.p_promo_sk
),
agg_sales AS (
   SELECT
        sales_channel,
        d_year,
        i_category,
        i_brand,
        ca_state,
        cd_gender,
        promo_active,
        SUM(net_paid) AS total_net_paid,
        SUM(quantity) AS total_quantity,
        CASE WHEN SUM(quantity) = 0 THEN 0 ELSE SUM(net_paid) / SUM(quantity) END AS avg_price_per_unit,
        approx_percentile(net_paid, 0.5) AS median_net_paid,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        RANK() OVER (PARTITION BY sales_channel ORDER BY SUM(net_paid) DESC) AS revenue_rank
   FROM joined_sales
   GROUP BY ROLLUP (sales_channel, d_year, i_category, i_brand, ca_state, cd_gender, promo_active)
)
SELECT *
FROM agg_sales
WHERE revenue_rank <= 10
ORDER BY sales_channel, revenue_rank, d_year, i_category, i_brand
