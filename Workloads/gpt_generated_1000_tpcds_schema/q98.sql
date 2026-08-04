WITH joined AS (
    SELECT
        cp.cp_department               AS department,
        cp.cp_type                     AS page_type,
        i.i_category                    AS category,
        i.i_brand                       AS brand,
        i.i_item_id                     AS item_id,
        ib.ib_upper_bound               AS income_upper_bound,
        hd.hd_vehicle_count            AS vehicle_count,
        cs.cs_quantity                  AS sale_quantity,
        cs.cs_ext_sales_price           AS cs_ext_sales_price,
        sr.sr_return_amt                AS sr_return_amt,
        ws.ws_ext_sales_price           AS ws_ext_sales_price
    FROM catalog_sales cs
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_start_date < DATE '2001-01-01'
      AND ib.ib_upper_bound >= 150000
      AND hd.hd_vehicle_count >= 2
      AND cs.cs_quantity > 5
      AND cp.cp_type = 'Special'
)
SELECT
    department,
    category,
    brand,
    item_id,
    SUM(cs_ext_sales_price)                         AS catalog_sales,
    SUM(COALESCE(sr_return_amt, 0))                 AS total_returns,
    SUM(COALESCE(ws_ext_sales_price, 0))            AS web_sales,
    (SUM(cs_ext_sales_price) - SUM(COALESCE(sr_return_amt, 0)) + SUM(COALESCE(ws_ext_sales_price, 0))) AS total_sales,
    RANK() OVER (PARTITION BY category ORDER BY (SUM(cs_ext_sales_price) - SUM(COALESCE(sr_return_amt, 0)) + SUM(COALESCE(ws_ext_sales_price, 0))) DESC) AS category_rank
FROM joined
GROUP BY department, category, brand, item_id
ORDER BY category_rank, total_sales DESC
LIMIT 100
