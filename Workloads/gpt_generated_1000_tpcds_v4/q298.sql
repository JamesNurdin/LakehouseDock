WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand,
           COUNT(*) AS warehouse_count
    FROM inventory
    WHERE inv_warehouse_sk IN (10, 12, 14)               -- selective filter on warehouse
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    COUNT(DISTINCT ss.ss_ticket_number)          AS store_sales_cnt,
    SUM(ss.ss_ext_sales_price)                  AS store_sales_total,
    COUNT(DISTINCT ws.ws_order_number)          AS web_sales_cnt,
    SUM(ws.ws_ext_sales_price)                  AS web_sales_total,
    SUM(p.p_cost)                               AS total_promo_cost,
    SUM(inv_agg.total_qty_on_hand)              AS total_inventory_qty,
    MIN(i.i_current_price)                      AS min_price,
    MAX(i.i_current_price)                      AS max_price,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM item i
LEFT JOIN store_sales ss
       ON ss.ss_item_sk = i.i_item_sk                     -- store_sales ↔ item
LEFT JOIN web_sales ws
       ON ws.ws_item_sk = i.i_item_sk                     -- web_sales ↔ item
LEFT JOIN promotion p
       ON p.p_item_sk = i.i_item_sk                       -- promotion ↔ item
LEFT JOIN inventory_agg inv_agg
       ON inv_agg.inv_item_sk = i.i_item_sk               -- inventory (aggregated) ↔ item
LEFT JOIN customer c
       ON c.c_customer_sk = ss.ss_customer_sk            -- store_sales ↔ customer
LEFT JOIN customer_address ca
       ON ca.ca_address_sk = ss.ss_addr_sk               -- store_sales ↔ address
LEFT JOIN household_demographics hd
       ON hd.hd_demo_sk = ss.ss_hdemo_sk                 -- store_sales ↔ household_demographics
LEFT JOIN income_band ib
       ON ib.ib_income_band_sk = hd.hd_income_band_sk    -- household_demographics ↔ income_band
LEFT JOIN web_site wsite
       ON wsite.web_site_sk = ws.ws_web_site_sk          -- web_sales ↔ web_site
WHERE i.i_current_price BETWEEN 10 AND 100               -- price range filter
  AND c.c_preferred_cust_flag = 'Y'                       -- preferred customers only
  AND wsite.web_country = 'United States'                -- US web sites only
GROUP BY
    i.i_item_id,
    i.i_product_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY store_sales_total DESC
LIMIT 100
