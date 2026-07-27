WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_category,
        i.i_brand,
        MIN(ca.ca_location_type) AS location_type,
        MIN(hd.hd_vehicle_count) AS min_vehicle_count,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_size IN ('small', 'large')
      AND ca.ca_location_type = 'apartment'
      AND hd.hd_vehicle_count >= 2
    GROUP BY ROLLUP (i.i_category, i.i_brand, cs.cs_item_sk)
)
SELECT
    sa.i_category,
    sa.i_brand,
    sa.cs_item_sk,
    sa.total_net_profit,
    sa.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY sa.i_category ORDER BY sa.total_net_profit DESC) AS product_rank_in_category,
    COALESCE(sr.avg_return_amt, 0) AS avg_store_return_amt,
    COALESCE(wr.avg_return_amt, 0) AS avg_web_return_amt,
    sa.location_type,
    sa.min_vehicle_count
FROM sales_agg sa
LEFT JOIN (
    SELECT
        sr_item_sk,
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
) sr ON sa.cs_item_sk = sr.sr_item_sk
LEFT JOIN (
    SELECT
        wr_item_sk,
        AVG(wr_return_amt) AS avg_return_amt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_item_sk
) wr ON sa.cs_item_sk = wr.wr_item_sk
WHERE (
        sa.i_category IS NOT NULL
        AND sa.total_quantity > 0
        AND EXISTS (
            SELECT 1
            FROM inventory inv
            JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
            WHERE inv.inv_item_sk = sa.cs_item_sk
              AND inv.inv_quantity_on_hand > 0
              AND w.w_state = 'CA'
        )
    )
ORDER BY sa.i_category, product_rank_in_category
LIMIT 100
