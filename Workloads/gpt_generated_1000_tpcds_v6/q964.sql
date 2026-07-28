WITH
    store_sales_agg AS (
        SELECT
            ss_item_sk,
            ss_customer_sk,
            ss_hdemo_sk,
            ss_sold_time_sk,
            ss_promo_sk,
            SUM(ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
            SUM(ss_quantity) AS total_quantity,
            ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS item_rank
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY ss_item_sk, ss_customer_sk, ss_hdemo_sk, ss_sold_time_sk, ss_promo_sk
    ),
    catalog_sales_agg AS (
        SELECT
            cs_item_sk,
            cs_bill_customer_sk,
            cs_bill_hdemo_sk,
            cs_sold_time_sk,
            cs_promo_sk,
            cs_call_center_sk,
            cs_catalog_page_sk,
            cs_ship_mode_sk,
            SUM(cs_ext_sales_price) AS total_ext_sales_price,
            SUM(cs_quantity) AS total_quantity_cs
        FROM catalog_sales
        WHERE cs_sold_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY cs_item_sk, cs_bill_customer_sk, cs_bill_hdemo_sk, cs_sold_time_sk, cs_promo_sk, cs_call_center_sk, cs_catalog_page_sk, cs_ship_mode_sk
    ),
    web_sales_agg AS (
        SELECT
            ws_item_sk,
            ws_bill_customer_sk,
            ws_bill_hdemo_sk,
            ws_sold_time_sk,
            ws_promo_sk,
            SUM(ws_net_paid) AS total_net_paid,
            SUM(ws_quantity) AS total_quantity_ws
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY ws_item_sk, ws_bill_customer_sk, ws_bill_hdemo_sk, ws_sold_time_sk, ws_promo_sk
    ),
    store_returns_agg AS (
        SELECT
            sr_item_sk,
            SUM(sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt,
            MAX(sr_reason_sk) AS any_reason_sk
        FROM store_returns
        WHERE sr_returned_date_sk BETWEEN 2450815 AND 2450825
        GROUP BY sr_item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_lower_bound >= 80000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 50000 THEN 'Mid Income'
        ELSE 'Low Income'
    END AS income_category,
    c.c_first_name,
    td.t_hour,
    ss_agg.total_net_paid_inc_tax,
    cs_agg.total_ext_sales_price,
    ws_agg.total_net_paid,
    COALESCE(sr_agg.total_return_amt, 0) AS total_return_amount,
    COUNT(*) OVER (PARTITION BY i.i_item_sk) AS item_occurrences,
    RANK() OVER (ORDER BY ss_agg.total_net_paid_inc_tax DESC) AS sales_rank
FROM store_sales_agg ss_agg
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_returns_agg sr_agg
    ON sr_agg.sr_item_sk = ss_agg.ss_item_sk
JOIN catalog_sales_agg cs_agg
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN web_sales_agg ws_agg
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN time_dim td
    ON cs_agg.cs_sold_time_sk = td.t_time_sk
WHERE EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr_agg.any_reason_sk
          AND r.r_reason_desc LIKE '%defect%'
    )
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
ORDER BY sales_rank
LIMIT 100
