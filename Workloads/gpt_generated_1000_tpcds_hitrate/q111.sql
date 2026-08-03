WITH sales_promo AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        p.p_promo_sk,
        p.p_discount_active
    FROM catalog_sales cs
    FULL OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
)
SELECT
    cc.cc_name,
    cp.cp_type,
    sm.sm_carrier,
    cd.cd_gender,
    hd.hd_buy_potential,
    CASE WHEN sp.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    SUM(sp.cs_net_paid) AS total_net_paid,
    AVG(sp.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT sp.cs_order_number) AS distinct_orders,
    MIN(sp.cs_ship_date_sk) AS earliest_ship_sk,
    MAX(sp.cs_ship_date_sk) AS latest_ship_sk
FROM sales_promo sp
INNER JOIN call_center cc
    ON sp.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON sp.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
    ON sp.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN customer c
    ON sp.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON sp.cs_bill_addr_sk = ca.ca_address_sk
INNER JOIN customer_demographics cd
    ON sp.cs_bill_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON sp.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_carrier = 'FEDEX'
  AND cd.cd_education_status = 'Advanced Degree'
GROUP BY
    cc.cc_name,
    cp.cp_type,
    sm.sm_carrier,
    cd.cd_gender,
    hd.hd_buy_potential,
    CASE WHEN sp.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
LIMIT 100
