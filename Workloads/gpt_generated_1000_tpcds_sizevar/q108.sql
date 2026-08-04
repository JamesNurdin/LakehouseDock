WITH cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_sales_price > 500
      AND cs_quantity >= 2
),
joined AS (
    SELECT
        s.s_store_name,
        p.p_promo_name,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_order_number,
        t.t_hour,
        cp.cp_type,
        r.r_reason_desc,
        wp.wp_type,
        wr.wr_net_loss
    FROM cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND hd.hd_buy_potential = 'Medium'
      AND p.p_discount_active = 'Y'
      AND s.s_number_employees > 250
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_type = 'Catalog'
)
SELECT
    s_store_name,
    p_promo_name,
    cd_credit_rating,
    hd_buy_potential,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    MIN(cs_ext_discount_amt) AS min_discount,
    MAX(cs_ext_discount_amt) AS max_discount
FROM joined
GROUP BY
    s_store_name,
    p_promo_name,
    cd_credit_rating,
    hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
