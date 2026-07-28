WITH catalog_data AS (
    SELECT 
        i.i_item_id AS item_id,
        cs.cs_ext_sales_price AS sales_amount,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND ib.ib_lower_bound >= 60001
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
web_data AS (
    SELECT 
        i.i_item_id AS item_id,
        ws.ws_ext_sales_price AS sales_amount,
        'web' AS source
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND ib.ib_lower_bound >= 60001
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
)
SELECT
    item_id,
    SUM(sales_amount) AS total_sales
FROM (
    SELECT item_id, sales_amount, source FROM catalog_data
    UNION ALL
    SELECT item_id, sales_amount, source FROM web_data
) combined
GROUP BY item_id
ORDER BY total_sales DESC
LIMIT 10
