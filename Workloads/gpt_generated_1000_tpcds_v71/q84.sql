WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        d.d_date,
        d.d_year,
        t.t_hour,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        wp.wp_type,
        wsit.web_name,
        inv.inv_quantity_on_hand,
        ca.ca_address_id
    FROM catalog_returns cr
    JOIN store_returns sr
      ON cr.cr_item_sk = sr.sr_item_sk
    JOIN web_sales ws
      ON cr.cr_item_sk = ws.ws_item_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
         AND w.w_warehouse_sk = inv.inv_warehouse_sk
         AND inv.inv_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_warehouse_sq_ft > 500000
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 25000
      AND r.r_reason_desc LIKE '%damage%'
)
SELECT
    jd.i_brand,
    jd.i_category,
    SUM(jd.cr_return_amount) AS total_return_amount,
    SUM(jd.ws_ext_sales_price) AS total_sales_price,
    COUNT(DISTINCT jd.c_customer_sk) AS distinct_customers,
    CASE
        WHEN jd.ib_upper_bound > 100000 THEN 'HighIncome'
        ELSE 'LowIncome'
    END AS income_group,
    ROW_NUMBER() OVER (PARTITION BY jd.i_brand ORDER BY SUM(jd.cr_net_loss) DESC) AS brand_rank
FROM joined_data jd
GROUP BY
    jd.i_brand,
    jd.i_category,
    jd.ib_upper_bound,
    CASE
        WHEN jd.ib_upper_bound > 100000 THEN 'HighIncome'
        ELSE 'LowIncome'
    END
HAVING SUM(jd.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
