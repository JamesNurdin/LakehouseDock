WITH joined_data AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        i.i_item_id,
        i.i_current_price,
        ib.ib_lower_bound,
        cp.cp_catalog_number,
        ss.ss_ext_sales_price AS store_sales,
        ws.ws_ext_sales_price AS web_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND i.i_current_price > 10
      AND ib.ib_lower_bound >= 40000
      AND cp.cp_catalog_number IN (3, 6)
      AND c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND wsit.web_gmt_offset = -5.00
)
SELECT
    c_customer_id,
    d_year,
    i_item_id,
    SUM(store_sales) AS total_store_sales,
    SUM(web_sales)   AS total_web_sales,
    SUM(store_sales + web_sales) AS total_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(store_sales + web_sales) DESC) AS sales_rank,
    CASE WHEN SUM(store_sales + web_sales) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
FROM joined_data
GROUP BY c_customer_id, d_year, i_item_id
HAVING SUM(store_sales + web_sales) > 10000
ORDER BY d_year, sales_rank
LIMIT 100
