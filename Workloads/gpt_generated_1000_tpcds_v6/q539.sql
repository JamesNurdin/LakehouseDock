WITH avg_tax_cte AS (
    SELECT AVG(cs_ext_tax) AS avg_tax
    FROM catalog_sales
)
SELECT
    cp.cp_department,
    bc.c_birth_country,
    bc.c_salutation,
    bc_cd.cd_gender,
    bc_hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer bc
    ON cs.cs_bill_customer_sk = bc.c_customer_sk
JOIN customer sc
    ON cs.cs_ship_customer_sk = sc.c_customer_sk
JOIN customer_demographics bcd
    ON cs.cs_bill_cdemo_sk = bcd.cd_demo_sk
JOIN customer_demographics scd
    ON cs.cs_ship_cdemo_sk = scd.cd_demo_sk
JOIN household_demographics bhd
    ON cs.cs_bill_hdemo_sk = bhd.hd_demo_sk
JOIN household_demographics shd
    ON cs.cs_ship_hdemo_sk = shd.hd_demo_sk
JOIN customer_demographics bc_cd
    ON bc.c_current_cdemo_sk = bc_cd.cd_demo_sk
JOIN household_demographics bc_hd
    ON bc.c_current_hdemo_sk = bc_hd.hd_demo_sk
WHERE cs.cs_ext_tax > (SELECT avg_tax FROM avg_tax_cte)
GROUP BY ROLLUP(
    cp.cp_department,
    bc.c_birth_country,
    bc.c_salutation,
    bc_cd.cd_gender,
    bc_hd.hd_buy_potential
)
ORDER BY total_net_paid DESC
LIMIT 100
