WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_time_sk,
        cs_catalog_page_sk,
        cs_order_number,
        cs_bill_customer_sk,
        cs_bill_hdemo_sk,
        cs_bill_addr_sk,
        SUM(cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_sales_price > 20.0
      AND cs_sold_time_sk IN (
          SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17
      )
    GROUP BY cs_item_sk, cs_sold_time_sk, cs_catalog_page_sk, cs_order_number,
             cs_bill_customer_sk, cs_bill_hdemo_sk, cs_bill_addr_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_brand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    r.r_reason_desc,
    ws.ws_net_paid AS web_net_paid,
    cr.cr_return_amount,
    s.total_sales,
    s.sales_cnt,
    cust.c_first_name,
    cust.c_last_name,
    addr.ca_state,
    td.t_hour,
    wp.wp_url,
    site.web_name
FROM sales_agg s
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON s.cs_sold_time_sk = td.t_time_sk
JOIN customer cust
    ON s.cs_bill_customer_sk = cust.c_customer_sk
JOIN household_demographics hd
    ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address addr
    ON s.cs_bill_addr_sk = addr.ca_address_sk
LEFT JOIN catalog_returns cr
    ON s.cs_order_number = cr.cr_order_number
   AND s.cs_item_sk = cr.cr_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
WHERE i.i_class_id IN (1, 7, 13)
  AND cp.cp_type = 'PROMO'
  AND addr.ca_country = 'United States'
  AND site.web_state = 'CA'
  AND td.t_meal_time = 'LUNCH'
ORDER BY s.total_sales DESC
LIMIT 100
