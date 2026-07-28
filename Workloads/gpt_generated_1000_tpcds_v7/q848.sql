/*
Goal: Compare total sales amount for promotions that used TV channel vs. Catalog channel in the year 2000, 
restricted to customers with certain dependency counts, and combine the two results using UNION ALL.
*/
SELECT
    combined.p_promo_name,
    combined.d_year,
    combined.page_number,
    combined.total_amount
FROM (
    SELECT
        p.p_promo_name AS p_promo_name,
        d.d_year AS d_year,
        cp.cp_catalog_page_number AS page_number,
        SUM(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE p.p_channel_tv = 'Y'
      AND d.d_year = 2000
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd
            WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
              AND cd.cd_dep_count >= 2
        )
    GROUP BY p.p_promo_name, d.d_year, cp.cp_catalog_page_number

    UNION ALL

    SELECT
        p.p_promo_name AS p_promo_name,
        d.d_year AS d_year,
        cp.cp_catalog_page_number AS page_number,
        SUM(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE p.p_channel_catalog = 'Y'
      AND d.d_year = 2000
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd
            WHERE cd.cd_demo_sk = cs.cs_bill_cdemo_sk
              AND cd.cd_dep_college_count >= 3
        )
    GROUP BY p.p_promo_name, d.d_year, cp.cp_catalog_page_number
) AS combined
ORDER BY combined.p_promo_name, combined.d_year, combined.page_number
