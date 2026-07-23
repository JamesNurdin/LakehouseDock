SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    i.i_brand AS brand,
    p.p_promo_name AS promo_name,
    t.t_hour AS hour_of_day,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost
FROM
    store_sales ss
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
    AND c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_returning_customer_sk = c.c_customer_sk
    AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
    AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    s.s_division_id = 1
    AND i.i_brand = 'BrandA'
    AND p.p_discount_active = 'Y'
    AND r_sr.r_reason_desc = 'Damaged'
    AND w.w_county = 'Bronx County'
    AND t.t_hour BETWEEN 9 AND 17
    AND c.c_birth_month = 5
    AND cp.cp_department = 'Electronics'
    AND wp.wp_type = 'Product'
    AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_sales_price > 2000
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_brand,
    p.p_promo_name,
    t.t_hour
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
    AND (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY
    total_sales DESC
LIMIT 100
