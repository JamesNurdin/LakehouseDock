WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk AS cs_sold_date_sk,
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_net_loss AS cr_net_loss,
        i.i_current_price AS i_current_price,
        cd.cd_gender AS cd_gender,
        cd.cd_education_status AS cd_education_status,
        cd.cd_dep_employed_count AS cd_dep_employed_count,
        w.w_state AS w_state,
        p.p_discount_active AS p_discount_active
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
           AND w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cd.cd_education_status = '4 yr Degree'
      AND cd.cd_dep_employed_count >= 3
      AND i.i_brand = 'BrandA'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    w_state,
    cd_gender,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cr_net_loss) AS total_return_loss,
    AVG(i_current_price) AS avg_item_price,
    MIN(cs_sold_date_sk) AS earliest_sold_date_sk
FROM joined_data
GROUP BY ROLLUP (w_state, cd_gender)
HAVING SUM(cs_net_paid) > 100000
ORDER BY w_state ASC NULLS LAST, cd_gender ASC NULLS LAST
