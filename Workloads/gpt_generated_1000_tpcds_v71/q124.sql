WITH filtered_items AS (
    SELECT i_item_sk, i_product_name
    FROM item
    WHERE regexp_like(i_product_name, '^Premium.*')
      AND i_color LIKE 'Red%'
),

catalog_agg AS (
    SELECT
        w.w_county AS county,
        hd.hd_buy_potential AS buy_potential,
        'Catalog' AS source,
        SUM(cs.cs_net_profit) AS total_amount,
        CASE
            WHEN SUM(cs.cs_net_profit) > (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_category
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_description LIKE '%special%'
      AND regexp_like(cp.cp_type, '^[A-Z]{2,}$')
    GROUP BY w.w_county, hd.hd_buy_potential
    HAVING SUM(cs.cs_net_profit) > 10000
),

web_agg AS (
    SELECT
        w.w_county AS county,
        hd.hd_buy_potential AS buy_potential,
        'Web' AS source,
        SUM(wr.wr_net_loss) AS total_amount,
        CASE
            WHEN SUM(wr.wr_net_loss) > 5000 THEN 'High Loss'
            ELSE 'Low Loss'
        END AS profit_category
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE wp.wp_url LIKE 'http%://%/promo/%'
      AND regexp_extract(wp.wp_url, 'promo/([^/]+)', 1) IS NOT NULL
    GROUP BY w.w_county, hd.hd_buy_potential
    HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT county, buy_potential, source, total_amount, profit_category
FROM catalog_agg
UNION ALL
SELECT county, buy_potential, source, total_amount, profit_category
FROM web_agg
ORDER BY county, buy_potential
