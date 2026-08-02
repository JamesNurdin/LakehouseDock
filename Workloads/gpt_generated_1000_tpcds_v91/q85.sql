WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        ss.ss_sales_price,
        ss.ss_ticket_number AS ticket,
        cs.cs_sales_price,
        sr.sr_return_amt,
        cr.cr_return_amount,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        cc.cc_tax_percentage,
        cc.cc_gmt_offset,
        sm_cs.sm_type,
        r_sr.r_reason_desc,
        c.c_customer_id,
        t_ss.t_hour AS sale_hour,
        t_sr.t_hour AS return_hour
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
      AND i.i_brand = 'Brand#45'
      AND s.s_state = 'CA'
      AND hd.hd_income_band_sk BETWEEN 8 AND 15
      AND cc.cc_tax_percentage > 5.00
),
 distinct_sales AS (
    SELECT DISTINCT ss_ticket_number AS ticket
    FROM store_sales
),
 distinct_catalog AS (
    SELECT DISTINCT cs_order_number AS ticket
    FROM catalog_sales
),
 tickets_diff AS (
    SELECT ticket FROM distinct_sales
    EXCEPT
    SELECT ticket FROM distinct_catalog
),
 aggregated AS (
    SELECT
        b.d_year,
        b.i_category,
        b.s_state,
        (COALESCE(b.ss_sales_price, 0) + COALESCE(b.cs_sales_price, 0) - COALESCE(b.sr_return_amt, 0) - COALESCE(b.cr_return_amount, 0) - COALESCE(b.wr_return_amt, 0)) AS net_amount,
        b.ticket,
        (SELECT MAX(cc2.cc_gmt_offset) FROM call_center cc2 WHERE cc2.cc_state = b.s_state) AS max_gmt_offset_state
    FROM base b
    WHERE b.ticket IN (SELECT ticket FROM tickets_diff)
)
SELECT
    d_year,
    i_category,
    s_state,
    SUM(net_amount) AS total_net_amount,
    AVG(net_amount) AS avg_net_amount,
    COUNT(DISTINCT ticket) AS distinct_ticket_cnt,
    MAX(max_gmt_offset_state) AS max_gmt_offset_state
FROM aggregated
GROUP BY ROLLUP (d_year, i_category, s_state)
HAVING SUM(net_amount) > 0
ORDER BY total_net_amount DESC
LIMIT 100
