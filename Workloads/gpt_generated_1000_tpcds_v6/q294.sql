WITH ds AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        SUM(ss_ext_sales_price) AS store_sales_total
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_item_sk
)
SELECT
    d.d_date,
    w.w_warehouse_name,
    p.p_promo_name,
    SUM(ds.store_sales_total)                         AS total_store_sales,
    SUM(cs.cs_ext_sales_price)                        AS total_catalog_sales,
    SUM(wr.wr_return_amt)                             AS total_web_return_amount,
    COUNT(DISTINCT p.p_promo_name)                    AS distinct_promo_cnt
FROM ds
JOIN date_dim d           ON ds.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t           ON ds.ss_sold_time_sk = t.t_time_sk
JOIN item i               ON ds.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs    ON cs.cs_sold_date_sk = d.d_date_sk
                           AND cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = i.i_item_sk
                           AND cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w          ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p          ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_item_sk = i.i_item_sk
JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws          ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND w.w_county = 'Marshall County'
  AND i.i_brand = 'Brand#12'
  AND ib.ib_lower_bound >= 50000
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY d.d_date, w.w_warehouse_name, p.p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
