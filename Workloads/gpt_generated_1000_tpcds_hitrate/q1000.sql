WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_item_sk,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        SUM(cs.cs_ext_sales_price)        AS total_ext_sales_price,
        COUNT(*)                          AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT cr.cr_item_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    )
    GROUP BY
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_item_sk
)
SELECT
    d.d_year,
    w.w_state,
    p.p_promo_name,
    hd.hd_buy_potential,
    COUNT(DISTINCT sa.cs_order_number)                                 AS orders,
    SUM(sa.total_net_paid)                                              AS sum_net_paid,
    AVG(sa.total_ext_sales_price)                                       AS avg_ext_sales_price,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount ELSE 0 END) AS sum_return_amount,
    COUNT(DISTINCT wr.wr_order_number)                                  AS web_return_orders,
    CASE WHEN SUM(sa.total_net_paid) > (
            SELECT AVG(cs.cs_net_paid)
            FROM catalog_sales cs
        ) THEN 'High' ELSE 'Low' END                                 AS net_category
FROM sales_agg sa
RIGHT OUTER JOIN date_dim d      ON sa.cs_sold_date_sk = d.d_date_sk
JOIN            time_dim t      ON sa.cs_sold_time_sk = t.t_time_sk
JOIN            warehouse w     ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN            promotion p     ON sa.cs_promo_sk = p.p_promo_sk
JOIN            customer c      ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN            household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN       catalog_returns cr      ON cr.cr_order_number = sa.cs_order_number
LEFT JOIN       reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN       web_returns wr          ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN       reason r_wr              ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN       web_page wp              ON wr.wr_web_page_sk = wp.wp_web_page_sk
                                         AND wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN       web_site ws              ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND t.t_hour BETWEEN 9 AND 17
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND hd.hd_buy_potential = '501-1000'
GROUP BY
    d.d_year,
    w.w_state,
    p.p_promo_name,
    hd.hd_buy_potential
ORDER BY
    sum_net_paid DESC
LIMIT 100
