-- Goal: List top items by combined store sales and inventory, compare with web sales, excluding items with returns.
WITH
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS i_item_sk,
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date   <= DATE '2000-12-31'
      AND NOT EXISTS (
            SELECT 1 FROM web_returns wr
            WHERE wr.wr_item_sk = i.i_item_sk
        )
    GROUP BY ss.ss_item_sk, i.i_item_id, i.i_category
),

inventory_agg AS (
    SELECT
        inv.inv_item_sk AS i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),

full_item_sales AS (
    SELECT
        COALESCE(ss.i_item_sk, inv.i_item_sk) AS item_sk,
        i.i_item_id AS item_id,
        i.i_category AS category,
        ss.total_sales,
        ss.total_quantity,
        inv.total_quantity_on_hand
    FROM store_sales_agg ss
    FULL OUTER JOIN inventory_agg inv
        ON ss.i_item_sk = inv.i_item_sk
    LEFT JOIN item i
        ON i.i_item_sk = COALESCE(ss.i_item_sk, inv.i_item_sk)
),

web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS i_item_sk,
        i.i_item_id AS item_id,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        CAST(NULL AS BIGINT) AS total_quantity_on_hand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date   <= DATE '2000-12-31'
      AND i.i_category = 'Sports'
    GROUP BY ws.ws_item_sk, i.i_item_id, i.i_category
)

SELECT
    fis.item_id,
    fis.category,
    fis.total_sales,
    fis.total_quantity,
    fis.total_quantity_on_hand,
    'store_inventory' AS source
FROM full_item_sales fis
WHERE fis.total_sales IS NOT NULL
UNION ALL
SELECT
    wsa.item_id,
    wsa.category,
    wsa.total_sales,
    wsa.total_quantity,
    wsa.total_quantity_on_hand,
    'web_sales' AS source
FROM web_sales_agg wsa
WHERE wsa.total_sales IS NOT NULL
ORDER BY total_sales DESC
LIMIT 100
