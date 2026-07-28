WITH sales_enriched AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cc.cc_name,
        cc.cc_state,
        cp.cp_type,
        cp.cp_description,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM catalog_sales cs
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND c.c_salutation = 'Mrs.'
      AND cd.cd_gender = 'F'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp2.cp_description LIKE '%Urban%'
      )
),
agg AS (
    SELECT
        se.cs_call_center_sk,
        se.cc_name,
        se.cc_state,
        SUM(se.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM sales_enriched se
    GROUP BY se.cs_call_center_sk, se.cc_name, se.cc_state
)
SELECT
    a.cc_name,
    a.cc_state,
    a.total_profit,
    a.sales_cnt,
    RANK() OVER (PARTITION BY a.cc_state ORDER BY a.total_profit DESC) AS profit_rank_state,
    ROW_NUMBER() OVER (ORDER BY a.total_profit DESC) AS overall_rank
FROM agg a
WHERE a.total_profit > 0
ORDER BY a.total_profit DESC
LIMIT 100
