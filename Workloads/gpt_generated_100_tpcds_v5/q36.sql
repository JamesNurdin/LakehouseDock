WITH sales_with_avg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_order_number,
        cc.cc_state,
        w.w_state,
        s.s_city,
        d_sold.d_year,
        p.p_purpose,
        i.inv_quantity_on_hand,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS qty_category,
        (
            SELECT AVG(cs3.cs_net_paid)
            FROM catalog_sales cs3
            WHERE cs3.cs_sold_date_sk = cs.cs_sold_date_sk
        ) AS avg_net_paid_same_day
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND p.p_purpose = 'Unknown'
      AND s.s_city = 'San Francisco'
      AND cs.cs_quantity > 5
      AND i.inv_quantity_on_hand < 200
)
SELECT
    d_year,
    cc_state,
    w_state,
    s_city,
    qty_category,
    SUM(cs_ext_sales_price) AS total_ext_sales_price,
    AVG(cs_ext_sales_price) AS avg_ext_sales_price,
    COUNT(DISTINCT cs_order_number) AS distinct_order_cnt,
    MIN(cs_ext_sales_price) AS min_ext_sales_price,
    MAX(cs_ext_sales_price) AS max_ext_sales_price,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(avg_net_paid_same_day) AS avg_daily_net_paid,
    SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_amt ELSE 0 END) AS total_return_amt_with_qty
FROM sales_with_avg
GROUP BY d_year, cc_state, w_state, s_city, qty_category
ORDER BY total_net_paid DESC
LIMIT 100
