WITH sales_item AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_ship_mode_sk,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_manufact,
        i.i_product_name,
        sm.sm_code
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_profit > -500
      AND cs.cs_catalog_page_sk IN (9, 43)
      AND sm.sm_code = 'AIR'
)
SELECT
    si.cs_order_number,
    si.i_item_id,
    si.i_category,
    si.i_manufact,
    si.cs_net_profit,
    COALESCE(inv.inv_quantity_on_hand, 0)                AS on_hand_quantity,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY si.i_category ORDER BY si.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN si.cs_net_profit > (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = si.cs_item_sk
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM sales_item si
LEFT JOIN inventory inv
    ON inv.inv_item_sk = si.cs_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = si.cs_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_quantity > 0
  AND si.i_manufact = 'barprically'
ORDER BY si.cs_net_profit DESC
LIMIT 100
