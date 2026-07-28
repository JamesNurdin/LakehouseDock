WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_brand AS brand,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        COUNT(DISTINCT cr.cr_order_number) AS return_cnt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
        AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv
        ON ss.ss_item_sk = inv.inv_item_sk
        AND ss.ss_sold_date_sk = inv.inv_date_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand1'
      AND s.s_state = 'CA'
      AND c.c_birth_year BETWEEN 1965 AND 1975
      AND ib.ib_upper_bound <= 50000
    GROUP BY s.s_store_id, i.i_brand, d.d_year
)
SELECT
    store_id,
    brand,
    year,
    total_sales,
    total_returns,
    order_cnt,
    return_cnt,
    (total_sales - total_returns) AS net_sales,
    ROW_NUMBER() OVER (ORDER BY (total_sales - total_returns) DESC) AS sales_rank,
    AVG(total_sales) OVER (PARTITION BY brand) AS avg_sales_by_brand
FROM sales_returns
WHERE (total_sales - total_returns) > 0
ORDER BY net_sales DESC
LIMIT 100
