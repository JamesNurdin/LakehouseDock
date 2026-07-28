SELECT
    s.s_store_id,
    i.i_category,
    td.t_hour,
    p.p_promo_id,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
FROM
    catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    c.c_birth_year BETWEEN 1970 AND 1990
    AND s.s_country = 'United States'
    AND i.i_category_id = 4
    AND p.p_discount_active = 'Y'
    AND td.t_hour BETWEEN 9 AND 17
    AND ib.ib_upper_bound > 50000
    AND r.r_reason_desc = 'Damaged'
GROUP BY
    s.s_store_id,
    i.i_category,
    td.t_hour,
    p.p_promo_id
