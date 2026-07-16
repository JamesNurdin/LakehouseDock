WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        i.i_category,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count
    FROM (
        SELECT ss_sold_date_sk AS date_sk,
               ss_net_paid AS net_paid,
               ss_net_profit AS net_profit,
               ss_customer_sk AS cust_sk,
               ss_item_sk AS item_sk
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk,
               cs_net_paid,
               cs_net_profit,
               cs_bill_customer_sk,
               cs_item_sk
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_net_paid,
               ws_net_profit,
               ws_bill_customer_sk,
               ws_item_sk
        FROM web_sales
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN customer c ON s.cust_sk = c.c_customer_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, c.c_customer_id, i.i_category
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(transaction_count) AS total_transactions
FROM sales_agg
GROUP BY d_year, d_month_seq, i_category
ORDER BY sum_net_paid DESC
LIMIT 50
