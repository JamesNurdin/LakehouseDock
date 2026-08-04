WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sold_items AS (
    SELECT cs_item_sk
    FROM sales_sample
),
returned_items AS (
    SELECT wr_item_sk AS cs_item_sk
    FROM web_returns
),
items_not_returned AS (
    SELECT cs_item_sk
    FROM sold_items
    EXCEPT
    SELECT cs_item_sk
    FROM returned_items
),
main_agg AS (
    SELECT
        cc.cc_name,
        sm.sm_carrier,
        cd_bill.cd_gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        CASE
            WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM sales_sample cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    WHERE i.i_item_sk IN (SELECT cs_item_sk FROM items_not_returned)
    GROUP BY cc.cc_name, sm.sm_carrier, cd_bill.cd_gender
)
SELECT *
FROM main_agg
ORDER BY profit_rank
LIMIT 100
