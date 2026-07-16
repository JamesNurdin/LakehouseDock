WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           'store' AS channel,
           ss.ss_store_sk AS channel_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           'catalog',
           cs.cs_call_center_sk,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           'web',
           ws.ws_web_page_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
),
sales_enriched AS (
    SELECT us.*,
           d.d_year,
           d.d_moy AS sales_month,
           d.d_date AS sold_date,
           i.i_category,
           i.i_class,
           i.i_brand,
           i.i_color,
           i.i_size,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           CASE WHEN us.channel = 'store' THEN s.s_store_name END AS store_name,
           CASE WHEN us.channel = 'catalog' THEN cc.cc_name END AS call_center_name,
           CASE WHEN us.channel = 'web' THEN wp.wp_url END AS web_page_url
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    JOIN customer c ON us.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s ON us.channel = 'store' AND us.channel_sk = s.s_store_sk
    LEFT JOIN call_center cc ON us.channel = 'catalog' AND us.channel_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON us.channel = 'web' AND us.channel_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND cd.cd_gender = 'F'
),
monthly_agg AS (
    SELECT channel,
           d_year,
           sales_month,
           i_category,
           SUM(net_profit) AS total_net_profit,
           SUM(net_paid) AS total_net_paid,
           SUM(quantity) AS total_quantity,
           COUNT(*) AS sales_cnt
    FROM sales_enriched
    GROUP BY GROUPING SETS (
        (channel, d_year, sales_month, i_category),
        (channel, d_year, sales_month),
        (channel, i_category),
        (channel, d_year),
        (channel)
    )
),
profit_growth AS (
    SELECT ma.channel,
           ma.d_year,
           ma.sales_month,
           ma.i_category,
           ma.total_net_profit,
           LAG(ma.total_net_profit) OVER (PARTITION BY ma.channel, ma.i_category ORDER BY ma.d_year, ma.sales_month) AS prior_profit,
           (ma.total_net_profit - LAG(ma.total_net_profit) OVER (PARTITION BY ma.channel, ma.i_category ORDER BY ma.d_year, ma.sales_month))
           / NULLIF(LAG(ma.total_net_profit) OVER (PARTITION BY ma.channel, ma.i_category ORDER BY ma.d_year, ma.sales_month), 0) AS yoy_growth
    FROM monthly_agg ma
    WHERE ma.i_category IS NOT NULL
)
SELECT channel,
       d_year,
       sales_month,
       i_category,
       total_net_profit,
       prior_profit,
       yoy_growth,
       RANK() OVER (PARTITION BY channel, d_year, sales_month ORDER BY total_net_profit DESC) AS category_profit_rank
FROM profit_growth
WHERE yoy_growth IS NOT NULL
ORDER BY channel, d_year, sales_month, yoy_growth DESC
LIMIT 200
