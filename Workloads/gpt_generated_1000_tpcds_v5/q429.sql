WITH joined_data AS (
    SELECT
        cc_sales.cc_division_name,
        r.r_reason_desc,
        cs.cs_net_profit,
        cr.cr_refunded_cash,
        cs.cs_order_number,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category,
        p.p_promo_name,
        cc_sales.cc_name,
        sm_sales.sm_type,
        cp_sales.cp_department
    FROM catalog_sales cs
    JOIN call_center cc_sales
      ON cs.cs_call_center_sk = cc_sales.cc_call_center_sk
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc_return
      ON cr.cr_call_center_sk = cc_return.cc_call_center_sk
    JOIN catalog_page cp_sales
      ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN catalog_page cp_return
      ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    JOIN ship_mode sm_sales
      ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
    JOIN ship_mode sm_return
      ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND cc_sales.cc_name LIKE '%call%'
      AND substring(p.p_promo_name, 1, 5) = 'Promo'
)
SELECT
    division_name,
    reason_desc,
    profit_category,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT order_number) AS distinct_orders
FROM (
    SELECT
        cc_division_name AS division_name,
        r_reason_desc AS reason_desc,
        profit_category,
        cs_net_profit AS total_net_profit,
        cr_refunded_cash AS total_refunded_cash,
        cs_order_number AS order_number
    FROM joined_data
) agg
GROUP BY division_name, reason_desc, profit_category
ORDER BY total_net_profit DESC
