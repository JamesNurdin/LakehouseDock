WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_bill_cdemo_sk,
        cs_bill_hdemo_sk,
        SUM(cs_ext_sales_price)          AS total_sales,
        SUM(cs_net_profit)               AS total_profit,
        COUNT(DISTINCT cs_order_number)  AS distinct_orders
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 500                     -- filter predicate 1
    GROUP BY cs_item_sk, cs_call_center_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk
),
inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_quantity_on_hand > 0                -- filter predicate 2
    GROUP BY inv_item_sk
),
returns_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt)                AS total_returns,
        COUNT(DISTINCT wr_return_quantity) AS distinct_return_qty
    FROM web_returns
    WHERE wr_return_amt > 100                     -- filter predicate 3
    GROUP BY wr_item_sk
),
intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM catalog_sales WHERE cs_coupon_amt > 2000
    INTERSECT
    SELECT wr_item_sk      FROM web_returns   WHERE wr_fee         > 50
),
except_items AS (
    SELECT cs_item_sk AS item_sk FROM cs_agg
    EXCEPT
    SELECT wr_item_sk      FROM returns_agg
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    cs_agg.total_sales,
    cs_agg.total_profit,
    inv_agg.total_inventory,
    returns_agg.total_returns,
    cs_agg.distinct_orders,
    returns_agg.distinct_return_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs_agg.total_sales DESC) AS category_rank,
    LAG(cs_agg.total_sales) OVER (PARTITION BY i.i_category ORDER BY cs_agg.total_sales DESC) AS prev_sales
FROM cs_agg
JOIN intersect_items ii ON cs_agg.cs_item_sk = ii.item_sk
LEFT JOIN except_items ei ON cs_agg.cs_item_sk = ei.item_sk
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
JOIN returns_agg ON i.i_item_sk = returns_agg.wr_item_sk
WHERE cc.cc_state = 'CA'
  AND i.i_category = 'Electronics'
  AND ib.ib_lower_bound >= 50000
  AND ei.item_sk IS NULL               -- exclude items that appear in the EXCEPT set
ORDER BY cs_agg.total_sales DESC
LIMIT 100
