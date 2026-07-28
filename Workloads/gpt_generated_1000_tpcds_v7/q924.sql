WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_promo_sk AS promo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_tax_percentage > 0.05
      AND p.p_channel_dmail = 'Y'
      AND i.i_current_price > 20
    GROUP BY cs.cs_bill_customer_sk, cs.cs_call_center_sk, cs.cs_promo_sk
)
SELECT
    cc.cc_name,
    p.p_promo_name,
    AVG(sa.total_sales) AS avg_total_sales,
    SUM(sa.total_profit) AS total_profit_all
FROM sales_agg sa
JOIN tpcds.call_center cc
    ON sa.call_center_sk = cc.cc_call_center_sk
JOIN tpcds.promotion p
    ON sa.promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp
    ON sa.customer_sk = wp.wp_customer_sk
WHERE wp.wp_char_count > 1000
GROUP BY cc.cc_name, p.p_promo_name
HAVING SUM(sa.total_sales) > 100000
