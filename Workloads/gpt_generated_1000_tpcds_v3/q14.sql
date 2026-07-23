SELECT
    site.web_name AS website_name,
    hd.hd_buy_potential AS buy_potential,
    td.t_meal_time AS meal_time,
    c.c_salutation AS salutation,
    COUNT(*) AS num_sales,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_quantity) AS min_quantity,
    MAX(ws.ws_quantity) AS max_quantity,
    SUM(ws.ws_ext_sales_price) / COUNT(*) AS avg_sales_per_order
FROM
    web_sales ws
JOIN
    time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
JOIN
    customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN
    household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN
    income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN
    web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN
    web_site site
      ON ws.ws_web_site_sk = site.web_site_sk
WHERE
    ws.ws_quantity >= 30
    AND ws.ws_ext_tax > 100.00
    AND ws.ws_coupon_amt > 0.00
    AND c.c_salutation = 'Mr.'
    AND hd.hd_buy_potential = '>10000'
    AND ib.ib_lower_bound >= 50000
    AND td.t_hour BETWEEN 9 AND 17
    AND site.web_country = 'United States'
    AND ws.ws_ext_discount_amt > (
        SELECT AVG(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
    )
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'Landing'
    )
GROUP BY
    site.web_name,
    hd.hd_buy_potential,
    td.t_meal_time,
    c.c_salutation
ORDER BY
    total_sales DESC
LIMIT 100
