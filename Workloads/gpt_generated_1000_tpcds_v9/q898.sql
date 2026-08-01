WITH store_agg AS (
    SELECT
        ss_item_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS store_sales_amt,
        SUM(ss_quantity) AS store_qty,
        COUNT(*) AS store_txn_cnt
    FROM store_sales
    WHERE ss_ext_tax > 10
      AND ss_quantity > 3
      AND ss_wholesale_cost < 5000
    GROUP BY ss_item_sk, ss_promo_sk
),
channel_agg AS (
    SELECT
        i.i_category AS i_category,
        p.p_promo_name AS p_promo_name,
        SUM(sa.store_sales_amt) AS total_store_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT i.i_item_id) AS distinct_items
    FROM store_agg sa
    JOIN item i
        ON sa.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
       AND sa.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON i.i_item_sk = cs.cs_item_sk
       AND cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE i.i_formulation LIKE '%thistle%'
      AND i.i_manufact = 'barantipri'
      AND sm_cs.sm_carrier = 'PRIVATECARRIER'
      AND sm_ws.sm_carrier = 'PRIVATECARRIER'
      AND cs.cs_quantity > 5
      AND ws.ws_quantity >= 2
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'A'
    GROUP BY ROLLUP (i.i_category, p.p_promo_name)
)
SELECT
    COALESCE(i_category, 'ALL') AS category,
    p_promo_name,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    (total_store_sales + total_catalog_sales + total_web_sales) AS total_all_channels,
    distinct_items,
    SUM(total_store_sales + total_catalog_sales + total_web_sales) OVER () AS overall_total_sales,
    ROUND(
        (total_store_sales + total_catalog_sales + total_web_sales) * 100.0
        / SUM(total_store_sales + total_catalog_sales + total_web_sales) OVER (),
        2
    ) AS pct_of_total
FROM channel_agg
ORDER BY category, p_promo_name
