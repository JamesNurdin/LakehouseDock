WITH base AS (
    SELECT d.*
    FROM date_dim d
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
)
SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    cp.cp_department,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    (
        SELECT SUM(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
    ) AS total_year_store_net_paid
FROM base d
JOIN store_sales ss               ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t                    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd      ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd     ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca           ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s                       ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p                   ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs              ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr            ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_order_number = cs.cs_order_number
JOIN reason r                      ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv                 ON inv.inv_date_sk = d.d_date_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp                   ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_returns wr                ON wr.wr_returned_date_sk = d.d_date_sk
                                   AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc LIKE '%damaged%'
    AND w.w_city = 'Los Angeles'
    AND cp.cp_department = 'Electronics'
    AND inv.inv_quantity_on_hand > 0
GROUP BY
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    cp.cp_department
ORDER BY total_store_net_paid DESC
LIMIT 100
