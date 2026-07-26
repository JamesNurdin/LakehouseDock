WITH item_store_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    iss.total_quantity,
    iss.total_net_paid,
    CASE
        WHEN iss.total_net_paid >= 5000 THEN 'High'
        WHEN iss.total_net_paid >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY iss.total_net_paid DESC) AS sales_rank,
    AVG(iss.total_net_paid) OVER (PARTITION BY i.i_item_id ORDER BY s.s_store_sk ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS neighbor_avg_net_paid
FROM item_store_sales iss
JOIN store s ON iss.ss_store_sk = s.s_store_sk
JOIN item i ON iss.ss_item_sk = i.i_item_sk
ORDER BY s.s_store_name, sales_rank
LIMIT 15
