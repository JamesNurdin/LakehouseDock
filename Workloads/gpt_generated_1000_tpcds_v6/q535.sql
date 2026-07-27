WITH sales_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cc.cc_name,
        cc.cc_mkt_id,
        cc.cc_rec_start_date,
        cd.cd_purchase_estimate,
        cd.cd_gender,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_type
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_mkt_id IN (2, 5)
      AND cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND cd.cd_purchase_estimate >= 6000
      AND cp.cp_catalog_number = 15
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
)
SELECT
    sj.cc_name,
    sj.sm_type,
    sj.p_promo_name,
    SUM(sj.cs_ext_sales_price) AS total_sales,
    AVG(sj.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT sj.cs_order_number) AS distinct_orders,
    MIN(sj.cs_sold_date_sk) AS first_sold_date_sk,
    MAX(sj.cs_sold_date_sk) AS last_sold_date_sk
FROM sales_joined sj
GROUP BY sj.cc_name, sj.sm_type, sj.p_promo_name
HAVING SUM(sj.cs_ext_sales_price) > 100000
   AND AVG(sj.cs_net_profit) > 0
ORDER BY total_sales DESC
LIMIT 100
