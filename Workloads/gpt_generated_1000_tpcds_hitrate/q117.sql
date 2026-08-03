WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
      AND cs.cs_net_paid > 1000
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND ws.ws_net_paid > 1000
),
agg AS (
    SELECT
        d_cs.d_year,
        c.c_customer_id,
        p.p_promo_name,
        CASE WHEN cs.cs_ext_sales_price > 5000 THEN 'Large' ELSE 'Small' END AS sale_size,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MAX(ws.ws_net_profit) AS max_web_profit,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(wr.wr_return_amt) AS total_web_return
    FROM customer c
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_cs.d_date_sk
    WHERE c.c_birth_country = 'United States'
      AND d_cs.d_year = 2001
      AND inv.inv_quantity_on_hand > 500
      AND p.p_discount_active = 'Y'
      AND t_cs.t_hour = 14
      AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
    GROUP BY
        d_cs.d_year,
        c.c_customer_id,
        p.p_promo_name,
        CASE WHEN cs.cs_ext_sales_price > 5000 THEN 'Large' ELSE 'Small' END
)
SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rn
    FROM agg
) t
WHERE rn <= 10
ORDER BY d_year, total_net_paid DESC
LIMIT 100
