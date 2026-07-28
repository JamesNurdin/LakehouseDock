WITH
    store_part AS (
        SELECT
            i.i_item_id,
            d.d_year,
            ss.ss_net_profit AS net_profit,
            CASE WHEN ss.ss_net_profit > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) THEN 1 ELSE 0 END AS above_avg_profit,
            EXISTS (
                SELECT 1
                FROM catalog_sales cs
                WHERE cs.cs_item_sk = ss.ss_item_sk
                  AND cs.cs_sold_date_sk = d.d_date_sk
            ) AS sold_in_catalog
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
          AND i.i_brand = 'Brand#12'
    ),
    catalog_part AS (
        SELECT
            i.i_item_id,
            d.d_year,
            cs.cs_net_profit AS net_profit,
            CASE WHEN cs.cs_net_profit > (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 1 ELSE 0 END AS above_avg_profit,
            EXISTS (
                SELECT 1
                FROM store_sales ss2
                WHERE ss2.ss_item_sk = cs.cs_item_sk
                  AND ss2.ss_sold_date_sk = d.d_date_sk
            ) AS sold_in_store
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE d.d_year = 2001
          AND w.w_country = 'United States'
    )
SELECT
    combined.i_item_id,
    combined.d_year,
    combined.net_profit,
    combined.above_avg_profit,
    combined.sold_flag
FROM (
    SELECT i_item_id, d_year, net_profit, above_avg_profit, sold_in_catalog AS sold_flag
    FROM store_part
    UNION ALL
    SELECT i_item_id, d_year, net_profit, above_avg_profit, sold_in_store AS sold_flag
    FROM catalog_part
) AS combined
WHERE combined.net_profit > 0
ORDER BY combined.d_year DESC, combined.net_profit DESC
LIMIT 100
