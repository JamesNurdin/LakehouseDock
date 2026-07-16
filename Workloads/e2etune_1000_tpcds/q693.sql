WITH agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        cd.cd_education_status,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        (SUM(ss.ss_quantity) / NULLIF(AVG(inv.inv_quantity_on_hand), 0)) AS inventory_turnover
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cd.cd_education_status = 'College'
      AND cd.cd_purchase_estimate >= 1500
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND inv.inv_quantity_on_hand > 0
    GROUP BY i.i_category, i.i_brand, cd.cd_education_status
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    a.i_category,
    a.i_brand,
    a.cd_education_status,
    a.total_sales,
    a.total_profit,
    a.avg_discount,
    a.total_quantity_sold,
    a.avg_inventory_on_hand,
    a.inventory_turnover,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 10
