WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_paid)            AS total_net_paid,
        SUM(ss.ss_net_profit)          AS total_net_profit,
        SUM(ss.ss_quantity)            AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_sold_date_sk, ss.ss_ticket_number
)
SELECT
    d.d_year,
    s.s_store_sk,
    s.s_store_name,
    i.i_item_id,
    SUM(ssa.total_net_paid)                     AS store_sales_net,
    SUM(cr.cr_return_amount)                     AS catalog_return_amount,
    SUM(wr.wr_return_amt)                       AS web_return_amt,
    (
        SELECT COUNT(*)
        FROM store_returns sr_inner
        WHERE sr_inner.sr_store_sk = s.s_store_sk
    )                                            AS store_return_cnt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ssa.total_net_paid) DESC) AS sales_rank,
    CASE WHEN SUM(ssa.total_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM ss_agg ssa
JOIN store s
    ON s.s_store_sk = ssa.ss_store_sk
JOIN item i
    ON i.i_item_sk = ssa.ss_item_sk
JOIN date_dim d
    ON d.d_date_sk = ssa.ss_sold_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
JOIN reason r_cr
    ON r_cr.r_reason_sk = cr.cr_reason_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ssa.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON r_sr.r_reason_sk = sr.sr_reason_sk
JOIN time_dim t
    ON t.t_time_sk = cs.cs_sold_time_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wr.wr_item_sk = i.i_item_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_units = 'Case'
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cc.cc_class = 'A'
  AND r_cr.r_reason_desc LIKE '%damage%'
GROUP BY ROLLUP (d.d_year, s.s_store_sk, s.s_store_name, i.i_item_id)
LIMIT 100
