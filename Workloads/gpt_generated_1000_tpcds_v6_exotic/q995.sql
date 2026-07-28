WITH sub_a AS (
    SELECT
        td.t_hour AS hour,
        CAST(NULL AS varchar) AS carrier,
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_cnt,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_returns
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
                              AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 10 AND 15
      AND r.r_reason_desc LIKE '%duplicate%'
      AND sr.sr_return_quantity > 1
    GROUP BY ROLLUP (td.t_hour, p.p_promo_id)
),
sub_b AS (
    SELECT
        td.t_hour AS hour,
        sm.sm_carrier AS carrier,
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT cs.cs_order_number) AS sales_cnt,
        SUM(cs.cs_net_paid) AS total_sales,
        CAST(0 AS decimal(7,2)) AS total_returns
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE td.t_hour BETWEEN 9 AND 18
      AND sm.sm_carrier = 'FEDEX'
      AND p.p_discount_active = 'Y'
    GROUP BY ROLLUP (td.t_hour, sm.sm_carrier, p.p_promo_id)
)
SELECT hour,
       carrier,
       promo_id,
       sales_cnt,
       total_sales,
       total_returns
FROM sub_a
UNION ALL
SELECT hour,
       carrier,
       promo_id,
       sales_cnt,
       total_sales,
       total_returns
FROM sub_b
ORDER BY hour,
         carrier,
         promo_id
LIMIT 100
