WITH joined AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cs.cs_net_paid_inc_ship_tax AS cs_net_paid_inc_ship_tax,
        ss.ss_net_paid AS ss_net_paid,
        wp.wp_type,
        wp.wp_autogen_flag
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_ext_list_price < 6000
      AND cd.cd_purchase_estimate BETWEEN 3000 AND 8000
      AND wp.wp_autogen_flag = 'Y'
      AND cs.cs_net_paid_inc_ship_tax > 1000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    SUM(cs_net_paid_inc_ship_tax) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT wp_type) AS distinct_page_types,
    RANK() OVER (ORDER BY SUM(cs_net_paid_inc_ship_tax) + SUM(ss_net_paid) DESC) AS revenue_rank
FROM joined
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender
ORDER BY revenue_rank
LIMIT 20
