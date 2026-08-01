WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        MAX(c.c_customer_id) AS c_customer_id,
        MAX(c.c_first_name) AS c_first_name,
        MAX(c.c_last_name) AS c_last_name,
        cp.cp_department,
        sm.sm_type,
        MIN(p.p_channel_tv) AS channel_tv,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_sales_price) AS avg_ext_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MIN(cs.cs_quantity) AS min_quantity,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_month = 5
        AND p.p_channel_catalog = 'N'
        AND p.p_channel_tv = 'N'
        AND sm.sm_code = 'AIR'
        AND sm.sm_type = 'EXPRESS'
        AND cs.cs_quantity > 1
    GROUP BY ROLLUP (c.c_customer_sk, cp.cp_department, sm.sm_type)
    HAVING SUM(cs.cs_net_paid) > 1000
)
SELECT
    c_customer_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    cp_department,
    sm_type,
    CASE WHEN channel_tv = 'Y' THEN 'TV Promo' ELSE 'Non-TV' END AS promo_type,
    total_net_paid,
    avg_ext_sales_price,
    order_cnt,
    min_quantity,
    max_sales_price,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_customer_sk = sales_agg.c_customer_sk
          AND cs_sub.cs_sold_date_sk > 20210101
    ) AS recent_sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY total_net_paid DESC) AS rn
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
