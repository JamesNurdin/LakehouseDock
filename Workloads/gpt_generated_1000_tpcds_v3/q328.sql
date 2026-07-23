/*
Goal: Analyze net profit and return loss by store location, promotion and catalog return reason, focusing on customers who had catalog returns shipped via mode 16 with a reversed charge > 100.0. The query compares each group’s profit to the overall profit, includes a region flag, and limits the result to the top 100 groups.
*/
WITH filtered_customers AS (
    SELECT DISTINCT cr_refunded_customer_sk AS customer_sk
    FROM catalog_returns
    WHERE cr_ship_mode_sk = 16
      AND cr_reversed_charge > 100.0
)
SELECT
    s.s_state,
    s.s_city,
    p.p_promo_name,
    r_cat.r_reason_desc AS catalog_reason_desc,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    MIN(ss.ss_sold_date_sk) AS min_sold_date_sk,
    MAX(ss.ss_sold_date_sk) AS max_sold_date_sk,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(ss.ss_net_profit) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_combined_loss,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    (SELECT SUM(ss_net_profit) FROM store_sales) AS overall_total_net_profit,
    SUM(ss.ss_net_profit) / (SELECT SUM(ss_net_profit) FROM store_sales) AS profit_share
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
  AND c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
  AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r_cat
  ON cr.cr_reason_sk = r_cat.r_reason_sk
JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason r_web
  ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_customer_sk = c.c_customer_sk
WHERE
    s.s_company_id = 1
    AND cc.cc_state = 'CA'
    AND wp.wp_link_count >= 10
    AND p.p_discount_active = 'Y'
    AND ss.ss_customer_sk IN (SELECT customer_sk FROM filtered_customers)
GROUP BY
    s.s_state,
    s.s_city,
    p.p_promo_name,
    r_cat.r_reason_desc,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END
ORDER BY
    total_net_profit DESC
LIMIT 100
