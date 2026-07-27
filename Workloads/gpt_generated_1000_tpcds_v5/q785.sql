WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        ss.ss_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 2
      AND i.i_brand = 'Brand#12'
    GROUP BY i.i_item_sk, i.i_category, i.i_brand, ss.ss_store_sk, s.s_store_name
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '>10000'
      AND cs.cs_quantity > 1
    GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_discount_amt > 500
      AND hd.hd_dep_count <= 5
    GROUP BY ws.ws_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_fee > 20
      AND hd.hd_buy_potential = '1001-5000'
    GROUP BY wr.wr_item_sk
),
inventory_latest AS (
    SELECT
        inv.inv_item_sk,
        MAX(inv.inv_quantity_on_hand) AS max_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    s.s_store_name,
    COALESCE(isales.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(cagg.catalog_sales_amount, 0) AS catalog_sales_amount,
    COALESCE(wagg.web_sales_amount, 0) AS web_sales_amount,
    COALESCE(ragg.total_return_amt, 0) AS total_return_amt,
    COALESCE(inv.max_quantity_on_hand, 0) AS max_quantity_on_hand,
    (COALESCE(isales.store_sales_amount, 0) + COALESCE(cagg.catalog_sales_amount, 0) + COALESCE(wagg.web_sales_amount, 0) - COALESCE(ragg.total_return_amt, 0)) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY (COALESCE(isales.store_sales_amount, 0) + COALESCE(cagg.catalog_sales_amount, 0) + COALESCE(wagg.web_sales_amount, 0) - COALESCE(ragg.total_return_amt, 0)) DESC) AS category_rank,
    (SELECT AVG(ws2.ws_ext_discount_amt)
       FROM web_sales ws2
       WHERE ws2.ws_item_sk = i.i_item_sk) AS avg_ws_discount
FROM item i
LEFT JOIN item_sales isales ON i.i_item_sk = isales.i_item_sk
LEFT JOIN catalog_agg cagg ON i.i_item_sk = cagg.cs_item_sk
LEFT JOIN web_sales_agg wagg ON i.i_item_sk = wagg.ws_item_sk
LEFT JOIN returns_agg ragg ON i.i_item_sk = ragg.wr_item_sk
LEFT JOIN inventory_latest inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN store s ON isales.ss_store_sk = s.s_store_sk
WHERE i.i_category = 'Sports'
  AND i.i_current_price BETWEEN 20 AND 200
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_quantity > 5
    )
ORDER BY net_sales DESC
LIMIT 100
