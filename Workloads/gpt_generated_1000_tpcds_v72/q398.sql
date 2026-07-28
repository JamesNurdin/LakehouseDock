WITH base AS (
    SELECT
        cs.cs_item_sk,
        i.i_category,
        i.i_brand_id,
        sm.sm_type AS ship_mode_type,
        s.s_state,
        w.w_city,
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit,
        COALESCE(sr.sr_return_amt, 0) AS store_return_amt,
        COALESCE(wr.wr_return_amt, 0) AS web_return_amt,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451150
      AND cs.cs_net_profit > 0
      AND i.i_brand_id IN (5003002, 1002001)
      AND s.s_state = 'CA'
      AND w.w_city = 'New York'
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_return_quantity > 0
      )
),
agg AS (
    SELECT
        i_category,
        ship_mode_type,
        SUM(cs_net_paid_inc_ship_tax) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(store_return_amt) AS total_store_returns,
        SUM(web_return_amt) AS total_web_returns,
        SUM(inventory_on_hand) AS total_inventory,
        COUNT(DISTINCT cs_item_sk) AS distinct_items
    FROM base
    GROUP BY ROLLUP (i_category, ship_mode_type)
),
final AS (
    SELECT
        i_category,
        SUM(total_sales) AS cat_sales,
        SUM(total_profit) AS cat_profit,
        SUM(total_store_returns) AS cat_store_returns,
        SUM(total_web_returns) AS cat_web_returns,
        SUM(total_inventory) AS cat_inventory,
        SUM(distinct_items) AS cat_distinct_items
    FROM agg
    WHERE i_category IS NOT NULL
    GROUP BY i_category
)
SELECT
    i_category,
    cat_sales,
    cat_profit,
    cat_store_returns,
    cat_web_returns,
    cat_inventory,
    cat_distinct_items,
    cat_profit / NULLIF(cat_sales, 0) AS profit_margin
FROM final
WHERE cat_sales > 20000
ORDER BY profit_margin DESC
LIMIT 100
