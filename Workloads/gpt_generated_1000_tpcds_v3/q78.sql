WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    s.s_state,
    p.p_promo_name,
    td.t_hour,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    MIN(sr.sr_return_amt) AS min_return_amount,
    MAX(wr.wr_net_loss) AS max_web_return_loss,
    (SELECT COUNT(DISTINCT wp2.wp_web_page_id) FROM web_page wp2) AS total_distinct_web_pages
FROM sales_agg ss
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wr.wr_returned_time_sk = td.t_time_sk
WHERE cp.cp_department = 'Electronics'
  AND ib.ib_lower_bound >= 50000
  AND s.s_zip = '26192'
GROUP BY
    s.s_state,
    p.p_promo_name,
    td.t_hour
ORDER BY total_sales DESC
LIMIT 100
