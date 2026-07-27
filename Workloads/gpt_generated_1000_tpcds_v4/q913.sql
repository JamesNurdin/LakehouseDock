WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk,
        cs_bill_hdemo_sk,
        cs_item_sk,
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS cs_total_sales,
        SUM(cs_quantity) AS cs_total_qty
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_ext_sales_price > 0
      AND cs_sold_date_sk BETWEEN 2452000 AND 2453000
    GROUP BY cs_bill_customer_sk, cs_bill_hdemo_sk, cs_item_sk, cs_ship_mode_sk
)
SELECT
    c.c_customer_id,
    ws.web_site_id,
    SUM(cs_agg.cs_total_sales) AS sum_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales,
    SUM(cs_agg.cs_total_sales + ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM cs_agg
JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON ws.ws_web_site_sk = ws.web_site_sk
WHERE c.c_birth_country IN ('UKRAINE', 'MEXICO')
  AND ws.web_state = 'TX'
  AND i.i_wholesale_cost > 1.00
  AND ib.ib_upper_bound <= 50000
  AND sm.sm_type = 'AIR'
GROUP BY c.c_customer_id, ws.web_site_id
HAVING SUM(cs_agg.cs_total_sales + ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
