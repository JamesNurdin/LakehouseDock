WITH base AS (
    SELECT d.d_year,
           i.i_category,
           f.channel,
           SUM(f.net_paid) AS total_net_paid,
           SUM(f.net_profit) AS total_net_profit,
           COUNT(*) AS total_transactions,
           COUNT(DISTINCT f.cust_sk) AS distinct_customers
    FROM (
        SELECT ss_sold_date_sk AS sold_date_sk,
               ss_item_sk AS item_sk,
               ss_customer_sk AS cust_sk,
               ss_net_paid AS net_paid,
               ss_net_profit AS net_profit,
               'store' AS channel
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk,
               cs_item_sk,
               cs_bill_customer_sk,
               cs_net_paid,
               cs_net_profit,
               'catalog'
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_item_sk,
               ws_bill_customer_sk,
               ws_net_paid,
               ws_net_profit,
               'web'
        FROM web_sales
    ) f
    JOIN date_dim d ON f.sold_date_sk = d.d_date_sk
    JOIN item i ON f.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, f.channel
)
SELECT base.*,
       RANK() OVER (PARTITION BY base.d_year ORDER BY base.total_net_profit DESC) AS profit_rank
FROM base
ORDER BY base.d_year, profit_rank
