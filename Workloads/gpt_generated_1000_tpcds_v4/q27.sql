WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_code,
        sm.sm_contract,
        c.c_email_address,
        td.t_hour,
        td.t_am_pm
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(p.p_promo_name, '202[0-9]$')
      AND regexp_like(sm.sm_contract, '^.{3}[A-Z]{2}$')
      AND c.c_email_address LIKE '%@example.com'
      AND cp.cp_description LIKE '%summer%'
)
SELECT
    cp_department,
    p_promo_name,
    sm_code,
    t_hour,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_quantity) AS avg_quantity,
    CONCAT(cp_department, '-', p_promo_name) AS dept_promo_key
FROM filtered_sales
GROUP BY
    cp_department,
    p_promo_name,
    sm_code,
    t_hour,
    CONCAT(cp_department, '-', p_promo_name)
ORDER BY total_profit DESC
LIMIT 100
