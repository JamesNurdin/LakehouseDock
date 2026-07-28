/* goal: Identify top‑selling items (by item id) across catalog sales, returns and inventory, broken down by promotion, call center and ship mode, after applying several business filters. The query joins all eight TPC‑DS tables, aggregates in two CTEs with slightly different filter sets, unions the results, and then re‑aggregates to produce a ranked list of items.
*/
WITH base AS (
    SELECT
        i.i_item_id,
        i.i_manager_id,
        i.i_class_id,
        i.i_formulation,
        p.p_promo_name,
        p.p_end_date_sk,
        cc.cc_name,
        cc.cc_state,
        sm.sm_type,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        sr.sr_refunded_cash,
        wr.wr_refunded_cash
    FROM tpcds.item i
    JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (3, 64)
      AND i.i_class_id = 14
      AND p.p_end_date_sk BETWEEN 2450300 AND 2450400
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND inv.inv_quantity_on_hand > 0
      AND sr.sr_refunded_cash > 50
      AND wr.wr_refunded_cash > 30
),
agg1 AS (
    SELECT
        i_item_id,
        p_promo_name,
        cc_name,
        sm_type,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(sr_return_amt) AS total_store_return,
        SUM(wr_return_amt) AS total_web_return,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM base
    GROUP BY i_item_id, p_promo_name, cc_name, sm_type
),
agg2 AS (
    SELECT
        i_item_id,
        p_promo_name,
        cc_name,
        sm_type,
        SUM(cs_ext_sales_price) * 0.9 AS total_sales,
        SUM(cs_net_profit) * 0.9 AS total_profit,
        SUM(sr_return_amt) * 0.9 AS total_store_return,
        SUM(wr_return_amt) * 0.9 AS total_web_return,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM base
    WHERE i_manager_id = 26
    GROUP BY i_item_id, p_promo_name, cc_name, sm_type
)
SELECT
    u.i_item_id,
    SUM(u.total_sales) AS sum_sales,
    AVG(u.total_profit) AS avg_profit,
    SUM(u.total_store_return + u.total_web_return) AS sum_returns,
    SUM(u.total_inventory) AS sum_inventory
FROM (
    SELECT * FROM agg1
    UNION ALL
    SELECT * FROM agg2
) u
GROUP BY u.i_item_id
HAVING SUM(u.total_sales) > 1000
ORDER BY sum_sales DESC
LIMIT 100
