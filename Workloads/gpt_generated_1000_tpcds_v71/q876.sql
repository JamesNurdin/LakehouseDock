WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        d.d_year,
        t.t_hour,
        i.i_color,
        i.i_brand,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        c.c_first_name,
        c.c_last_name,
        ca.ca_zip,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 12 AND 14
      AND s.s_state = 'CA'
      AND i.i_color = 'Blue'
      AND ca.ca_zip = '57783'
      AND p.p_discount_active = 'Y'
)
SELECT
    sb.s_store_name AS store_name,
    sb.d_year,
    SUM(sb.ss_ext_sales_price)                                   AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0))                        AS total_catalog_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0))                             AS total_store_return_loss,
    COUNT(DISTINCT sb.ss_customer_sk)                            AS unique_customers,
    AVG(sb.ss_ext_discount_amt)                                 AS avg_discount,
    ROW_NUMBER() OVER (PARTITION BY sb.d_year ORDER BY SUM(sb.ss_ext_sales_price) DESC) AS sales_rank
FROM sales_base sb
LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = sb.ss_item_sk
      AND cr.cr_returned_date_sk = sb.ss_sold_date_sk
LEFT JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = sb.ss_ticket_number
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        WHERE sr_ex.sr_customer_sk = sb.ss_customer_sk
    )
GROUP BY
    sb.s_store_name,
    sb.d_year
HAVING SUM(sb.ss_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
