WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        d.d_year,
        t.t_shift,
        c.c_birth_month,
        cd.cd_gender,
        hd.hd_income_band_sk,
        p.p_discount_active,
        p.p_promo_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND p.p_discount_active = 'Y'
)
SELECT
    COALESCE(sr.sr_ticket_number, base.ss_ticket_number) AS ticket_number,
    base.d_year,
    base.t_shift,
    SUM(CASE WHEN base.cd_gender = 'M' THEN base.ss_net_paid_inc_tax ELSE 0 END) AS male_net_paid,
    SUM(CASE WHEN base.cd_gender = 'F' THEN base.ss_net_paid_inc_tax ELSE 0 END) AS female_net_paid,
    COUNT(DISTINCT base.ss_customer_sk) AS unique_customers,
    ws.web_name,
    cs.cust_sales_cnt
FROM base
FULL OUTER JOIN store_returns sr
    ON sr.sr_item_sk = base.ss_item_sk
   AND sr.sr_ticket_number = base.ss_ticket_number
FULL OUTER JOIN catalog_returns cr
    ON cr.cr_order_number = base.ss_ticket_number
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_date_sk = base.ss_sold_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = base.ss_sold_date_sk
   AND wr.wr_returned_time_sk = base.ss_sold_time_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS cust_sales_cnt
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = base.ss_customer_sk
) cs
JOIN web_site ws
    ON ws.web_open_date_sk = base.ss_sold_date_sk
WHERE ws.web_country = 'United States'
GROUP BY
    COALESCE(sr.sr_ticket_number, base.ss_ticket_number),
    base.d_year,
    base.t_shift,
    ws.web_name,
    cs.cust_sales_cnt
ORDER BY male_net_paid DESC
LIMIT 100
