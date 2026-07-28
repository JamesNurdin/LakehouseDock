WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    i.i_brand,
    SUM(sa.total_store_sales) AS store_sales,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM ss_agg sa
JOIN date_dim d
  ON sa.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
  AND cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM item i2
    WHERE i2.i_brand = i.i_brand
      AND i2.i_color = i.i_color
      AND i2.i_item_sk <> i.i_item_sk
)
  AND d.d_year = 2002
GROUP BY GROUPING SETS (
    (d.d_year, i.i_category, i.i_brand),
    (d.d_year, i.i_category),
    (d.d_year)
)
HAVING SUM(sa.total_store_sales) > 10000
ORDER BY d.d_year, i.i_category, i.i_brand
