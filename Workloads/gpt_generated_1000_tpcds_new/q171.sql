WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        SUM(cs.cs_net_profit)          AS total_profit,
        SUM(cs.cs_quantity)            AS total_qty,
        AVG(cs.cs_ext_discount_amt)    AS avg_discount
    FROM catalog_sales cs
    GROUP BY
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk
),
overall_avg AS (
    SELECT AVG(total_profit) AS avg_profit_all
    FROM (
        SELECT SUM(cs_net_profit) AS total_profit
        FROM catalog_sales
        GROUP BY cs_call_center_sk
    ) t
)
SELECT
    cc.cc_name,
    td.t_hour,
    cp.cp_department,
    ca.ca_county,
    cd.cd_purchase_estimate,
    p.p_promo_name,
    sm.sm_type,
    sa.total_qty,
    sa.total_profit,
    CASE
        WHEN sa.total_profit > (SELECT avg_profit_all FROM overall_avg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM sales_agg sa
JOIN call_center cc        ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td           ON sa.cs_sold_time_sk   = td.t_time_sk
JOIN catalog_page cp       ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca   ON sa.cs_bill_addr_sk    = ca.ca_address_sk
JOIN customer_demographics cd ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p           ON sa.cs_promo_sk        = p.p_promo_sk
JOIN ship_mode sm          ON sa.cs_ship_mode_sk    = sm.sm_ship_mode_sk
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_department = 'DEPARTMENT'
    AND ca.ca_county IN ('Williams County', 'Madison County')
    AND cd.cd_purchase_estimate > 5000
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
GROUP BY
    cc.cc_name,
    td.t_hour,
    cp.cp_department,
    ca.ca_county,
    cd.cd_purchase_estimate,
    p.p_promo_name,
    sm.sm_type,
    sa.total_qty,
    sa.total_profit
ORDER BY
    sa.total_profit DESC
LIMIT 100
