WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        i.i_item_id,
        i.i_current_price,
        w.w_warehouse_name,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        wp.wp_url,
        site.web_city,
        hd.hd_buy_potential,
        ca.ca_state,
        (
            SELECT avg(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
        ) AS avg_return_amount_wh
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price > 50
      AND w.w_warehouse_sq_ft BETWEEN 10000 AND 50000
      AND site.web_city = 'Lakeview'
      AND hd.hd_buy_potential IN ('1001-5000', '>10000')
      AND cr.cr_return_amount > 20
)
SELECT
    jd.cr_order_number,
    jd.cr_return_amount,
    jd.avg_return_amount_wh,
    jd.i_item_id,
    jd.i_current_price,
    jd.w_warehouse_name,
    jd.ws_sales_price,
    jd.ws_ext_sales_price,
    jd.wp_url,
    jd.web_city,
    jd.hd_buy_potential,
    jd.ca_state,
    ROW_NUMBER() OVER (PARTITION BY jd.web_city ORDER BY jd.ws_ext_sales_price DESC) AS sales_rank_city,
    RANK() OVER (ORDER BY jd.cr_return_amount DESC) AS return_amount_rank
FROM joined_data jd
ORDER BY jd.web_city, sales_rank_city
LIMIT 100
