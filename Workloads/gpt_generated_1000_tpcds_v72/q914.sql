WITH sales_union AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_category,
        ss.ss_net_paid AS net_paid,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'

    UNION ALL

    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_category,
        cs.cs_net_paid AS net_paid,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
),
customer_agg AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        SUM(net_paid) AS total_net_paid,
        COUNT(DISTINCT sales_channel) AS channels_count
    FROM sales_union
    GROUP BY c_customer_id, c_first_name, c_last_name
)
SELECT DISTINCT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_net_paid,
    channels_count,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM customer_agg
WHERE total_net_paid > 0
ORDER BY total_net_paid DESC
LIMIT 100
