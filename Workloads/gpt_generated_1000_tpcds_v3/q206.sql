WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_category AS i_category,
        cd.cd_gender AS gender,
        cd.cd_credit_rating AS credit_rating,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(*) AS transaction_count,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High Profit'
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive Profit'
            ELSE 'Loss'
        END AS profit_category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cd.cd_dep_college_count <= 2
      AND cd.cd_purchase_estimate >= 7500
      AND i.i_formulation LIKE '%papaya%'
      AND i.i_manager_id IN (34, 19)
      AND ss.ss_ext_tax > 10
      AND ss.ss_list_price BETWEEN 50 AND 90
    GROUP BY i.i_item_id, i.i_category, cd.cd_gender, cd.cd_credit_rating
)
SELECT
    i_category,
    profit_category,
    SUM(total_sales) AS category_sales,
    SUM(total_quantity) AS category_quantity,
    AVG(avg_net_paid) AS avg_net_paid_per_txn,
    COUNT(*) AS num_items
FROM sales_agg
GROUP BY i_category, profit_category
HAVING SUM(total_sales) > 1000
ORDER BY category_sales DESC
LIMIT 100
