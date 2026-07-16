WITH base_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_ext_discount_amt AS discount,
           cs.cs_net_profit AS net_profit,
           c.c_customer_sk AS customer_sk,
           c.c_current_cdemo_sk AS cd_demo_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_ext_discount_amt AS discount,
           ss.ss_net_profit AS net_profit,
           c.c_customer_sk AS customer_sk,
           c.c_current_cdemo_sk AS cd_demo_sk,
           'store' AS channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_ext_discount_amt AS discount,
           ws.ws_net_profit AS net_profit,
           c.c_customer_sk AS customer_sk,
           c.c_current_cdemo_sk AS cd_demo_sk,
           'web' AS channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
sales_enriched AS (
    SELECT d.d_year,
           bs.channel,
           i.i_category,
           cd.cd_gender,
           SUM(bs.net_profit) AS total_net_profit,
           SUM(bs.net_paid) AS total_net_paid,
           SUM(bs.quantity) AS total_quantity,
           COUNT(DISTINCT bs.customer_sk) AS distinct_customers,
           AVG(CASE WHEN bs.net_paid > 0 THEN bs.discount / bs.net_paid END) AS avg_discount_ratio
    FROM base_sales bs
    JOIN date_dim d ON bs.date_sk = d.d_date_sk
    JOIN item i ON bs.item_sk = i.i_item_sk
    JOIN customer_demographics cd ON bs.cd_demo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, bs.channel, i.i_category, cd.cd_gender
),
category_stats AS (
    SELECT se.*,
           SUM(se.total_net_profit) OVER (PARTITION BY se.d_year, se.channel) AS channel_total_profit
    FROM sales_enriched se
),
category_ranked AS (
    SELECT cs.*,
           ROW_NUMBER() OVER (PARTITION BY cs.d_year, cs.channel ORDER BY cs.total_net_profit DESC) AS cat_rank
    FROM category_stats cs
),
final_stats AS (
    SELECT cr.*,
           cr.total_net_profit / NULLIF(cr.channel_total_profit, 0) AS profit_share,
           LAG(cr.total_net_profit) OVER (PARTITION BY cr.channel, cr.i_category, cr.cd_gender ORDER BY cr.d_year) AS prev_year_profit
    FROM category_ranked cr
    WHERE cr.cat_rank <= 5
)
SELECT d_year,
       channel,
       i_category,
       cd_gender,
       total_net_profit,
       total_net_paid,
       total_quantity,
       distinct_customers,
       avg_discount_ratio,
       cat_rank,
       profit_share,
       prev_year_profit,
       (total_net_profit - prev_year_profit) / NULLIF(prev_year_profit, 0) AS profit_yoy_change,
       total_net_profit / NULLIF(total_net_paid, 0) AS profit_margin
FROM final_stats
ORDER BY d_year, channel, cat_rank
