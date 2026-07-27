WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cp.cp_department,
        ca.ca_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        COALESCE(inv.inv_quantity_on_hand, 0) AS qty_on_hand,
        i.i_item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    WHERE
        cp.cp_department = 'Electronics'                     -- predicate 1
        AND i.i_brand = 'importobrand #6'                    -- predicate 2
        AND ca.ca_state = 'CA'                               -- predicate 3
        AND cs.cs_ship_date_sk BETWEEN 2450800 AND 2450900   -- predicate 4
        AND cs.cs_net_paid_inc_ship > 500                   -- predicate 5
        AND inv.inv_quantity_on_hand >= 10                  -- predicate 6
        AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity = 0) -- predicate 7
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_category,
        cp.cp_department,
        ca.ca_state,
        inv.inv_quantity_on_hand,
        i.i_item_sk
)
SELECT
    s.i_item_id,
    s.i_brand,
    s.i_category,
    s.cp_department,
    s.ca_state,
    s.total_sales,
    s.total_profit,
    s.orders,
    s.qty_on_hand,
    RANK() OVER (PARTITION BY s.i_brand ORDER BY s.total_sales DESC) AS brand_sales_rank,
    CASE WHEN s.total_profit > 10000 THEN 'High' ELSE 'Medium' END AS profit_level,
    (SELECT AVG(cs2.cs_net_profit)
     FROM catalog_sales cs2
     JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
     WHERE i2.i_brand = s.i_brand) AS avg_brand_profit
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
