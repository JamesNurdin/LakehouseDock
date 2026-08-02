/*
Goal: Rank item categories and brands by profit from catalog and web sales, including the maximum promotion cost per category/brand, while handling missing inventory with a full outer join and summarizing subtotals.
*/
WITH all_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        cs.cs_net_profit,
        ws.ws_net_profit,
        ss.ss_net_profit,
        inv.inv_quantity_on_hand,
        i.i_item_sk
    FROM web_sales ws
    INNER JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_item_sk = i.i_item_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    INNER JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE cc.cc_country = 'USA'
      AND i.i_category = 'Electronics'
      AND ws.ws_list_price > 100.0
      AND cs.cs_quantity >= 5
      AND cs.cs_sold_date_sk BETWEEN 2451500 AND 2452000
      AND wp.wp_link_count > 10
),
catalog_agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(cs_net_profit) AS profit,
        'catalog' AS source
    FROM all_data
    GROUP BY ROLLUP(i_category, i_brand)
),
web_agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(ws_net_profit) AS profit,
        'web' AS source
    FROM all_data
    GROUP BY ROLLUP(i_category, i_brand)
),
union_agg AS (
    SELECT i_category, i_brand, profit, source FROM catalog_agg
    UNION
    SELECT i_category, i_brand, profit, source FROM web_agg
)
SELECT
    u.i_category,
    u.i_brand,
    u.profit,
    u.source,
    ROW_NUMBER() OVER (PARTITION BY u.source ORDER BY u.profit DESC) AS profit_rank,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        JOIN item i2 ON p2.p_item_sk = i2.i_item_sk
        WHERE i2.i_category = u.i_category
          AND i2.i_brand = u.i_brand
    ) AS max_promo_cost
FROM union_agg u
WHERE u.profit IS NOT NULL
ORDER BY u.profit DESC
LIMIT 100
