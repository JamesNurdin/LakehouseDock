WITH joined AS (
    SELECT
        s.s_store_id,
        s.s_state,
        ws.t_hour,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        sr.sr_return_amt,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        ca.ca_street_type,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        cc.cc_state,
        cp.cp_department,
        sm.sm_type,
        wr.wr_return_amt,
        rp.r_reason_desc,
        wp.wp_type
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim ws
        ON ss.ss_sold_time_sk = ws.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    JOIN reason rp
        ON sr.sr_reason_sk = rp.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = ws.t_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = ws.t_time_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND ca.ca_street_type = 'Avenue'
      AND hd.hd_buy_potential = '1001-5000'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
)
SELECT
    s_state,
    t_hour,
    SUM(ss_ext_sales_price) AS store_sales_total,
    SUM(sr_return_amt)      AS store_returns_total,
    AVG(cs_ext_sales_price) AS avg_catalog_sales,
    COUNT(DISTINCT cs_item_sk) AS distinct_catalog_items,
    SUM(DISTINCT ss_quantity)   AS distinct_store_quantity,
    (SELECT MAX(ss_net_paid) FROM store_sales) AS max_store_net_paid,
    COUNT(*) AS row_cnt
FROM joined
WHERE s_store_id NOT IN (SELECT s_store_id FROM store WHERE s_state = 'WA')
GROUP BY GROUPING SETS (
    (s_state, t_hour),
    (s_state),
    (t_hour),
    ()
)
HAVING SUM(ss_ext_sales_price) > 1000
ORDER BY store_sales_total DESC
LIMIT 100
