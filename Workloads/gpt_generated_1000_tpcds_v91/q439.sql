WITH all_catalog_orders AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        c.c_customer_id,
        cs.cs_sold_date_sk,
        d.d_year,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_promo_sk,
        p.p_promo_name,
        cc.cc_class,
        cc.cc_call_center_id,
        t.t_hour,
        t.t_minute
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND cc.cc_class = 'large'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
      AND t.t_hour BETWEEN 9 AND 17
),
returned_orders AS (
    SELECT DISTINCT
        wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_ret
        ON wr.wr_refunded_customer_sk = c_ret.c_customer_sk
    WHERE d_ret.d_year = 2001
      AND wp.wp_autogen_flag = 'N'
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_net_loss > 0
),
non_returned_orders AS (
    SELECT cs_order_number
    FROM all_catalog_orders
    EXCEPT
    SELECT wr_order_number
    FROM returned_orders
)
SELECT
    aco.cs_order_number,
    aco.c_customer_id,
    aco.d_year,
    aco.cs_net_profit,
    aco.cs_ext_sales_price,
    aco.p_promo_name,
    aco.cc_call_center_id,
    aco.t_hour,
    RANK() OVER (PARTITION BY aco.d_year ORDER BY aco.cs_net_profit DESC) AS profit_rank
FROM all_catalog_orders aco
JOIN non_returned_orders nro
    ON aco.cs_order_number = nro.cs_order_number
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    WHERE ss.ss_customer_sk = aco.cs_bill_customer_sk
      AND d_ss.d_year = aco.d_year
      AND p_ss.p_discount_active = 'Y'
)
ORDER BY profit_rank, aco.cs_net_profit DESC
LIMIT 100
