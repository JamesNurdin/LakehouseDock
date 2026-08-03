WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (6, 12, 16, 20)
      AND inv_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY inv_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    inv_agg.total_on_hand
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN inv_agg ON ss.ss_item_sk = inv_agg.inv_item_sk
WHERE ss.ss_ext_list_price > 100.00
  AND ss.ss_coupon_amt < 500.00
  AND cd.cd_education_status = 'Advanced Degree'
  AND cd.cd_dep_count >= 2
  AND ss.ss_sold_date_sk = (
        SELECT MAX(ss2.ss_sold_date_sk)
        FROM store_sales ss2
    )
GROUP BY i.i_category, i.i_brand, inv_agg.total_on_hand
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_net_paid DESC, i.i_category
OFFSET 0 LIMIT 100
