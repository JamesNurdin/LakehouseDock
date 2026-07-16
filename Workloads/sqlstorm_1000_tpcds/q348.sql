WITH cat_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cc.cc_state AS state,
         i.i_category AS category,
         cs.cs_ext_sales_price AS sales,
         cs.cs_ext_discount_amt AS discount,
         cs.cs_net_profit AS profit,
         cs.cs_net_paid AS net_paid,
         cs.cs_quantity AS quantity,
         'catalog' AS channel
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE p.p_discount_active = 'Y' AND cd.cd_gender = 'F' AND cd.cd_education_status = 'College'
),
store_sales_agg AS (
  SELECT ss.ss_sold_date_sk AS date_sk,
         s.s_state AS state,
         i.i_category AS category,
         ss.ss_ext_sales_price AS sales,
         ss.ss_ext_discount_amt AS discount,
         ss.ss_net_profit AS profit,
         ss.ss_net_paid AS net_paid,
         ss.ss_quantity AS quantity,
         'store' AS channel
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE p.p_discount_active = 'Y' AND cd.cd_gender = 'F' AND cd.cd_education_status = 'College'
),
web_sales_agg AS (
  SELECT ws.ws_sold_date_sk AS date_sk,
         w.web_state AS state,
         i.i_category AS category,
         ws.ws_ext_sales_price AS sales,
         ws.ws_ext_discount_amt AS discount,
         ws.ws_net_profit AS profit,
         ws.ws_net_paid AS net_paid,
         ws.ws_quantity AS quantity,
         'web' AS channel
  FROM web_sales ws
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE p.p_discount_active = 'Y' AND cd.cd_gender = 'F' AND cd.cd_education_status = 'College'
),
combined_sales AS (
  SELECT * FROM cat_sales
  UNION ALL
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
)
SELECT agg.d_year,
       agg.d_quarter_name,
       agg.state,
       agg.category,
       agg.channel,
       agg.total_sales,
       agg.total_discount,
       agg.total_profit,
       agg.total_quantity,
       agg.avg_discount_rate,
       RANK() OVER (PARTITION BY agg.d_year, agg.d_quarter_name ORDER BY agg.total_profit DESC) AS profit_rank
FROM (
  SELECT d.d_year,
         d.d_quarter_name,
         cs.state,
         cs.category,
         cs.channel,
         SUM(cs.sales) AS total_sales,
         SUM(cs.discount) AS total_discount,
         SUM(cs.profit) AS total_profit,
         SUM(cs.quantity) AS total_quantity,
         AVG(CASE WHEN cs.sales > 0 THEN cs.discount / cs.sales ELSE 0 END) AS avg_discount_rate
  FROM combined_sales cs
  JOIN date_dim d ON cs.date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year,
           d.d_quarter_name,
           cs.state,
           cs.category,
           cs.channel
  HAVING SUM(cs.sales) > 10000
) agg
ORDER BY agg.d_year, agg.d_quarter_name, agg.total_profit DESC
LIMIT 100
