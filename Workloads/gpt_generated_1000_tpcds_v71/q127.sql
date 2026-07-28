WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_ext_sales_price)      AS total_sales,
        SUM(cs.cs_net_profit)           AS total_profit,
        COUNT(*)                        AS sales_cnt,
        AVG(cs.cs_quantity)             AS avg_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold          ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w             ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i                  ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p             ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN customer c              ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
      AND i.i_category_id = 5
      AND w.w_state = 'CA'
      AND cc.cc_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND cs.cs_quantity >= 2
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk
)
SELECT
    i.i_product_name,
    i.i_category,
    cc.cc_name               AS call_center_name,
    w.w_warehouse_name,
    d_sold.d_date,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    sa.avg_quantity,
    inv.inv_quantity_on_hand,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = sa.cs_sold_date_sk
    )                         AS avg_profit_same_day,
    ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY sa.total_sales DESC) AS sales_rank
FROM sales_agg sa
JOIN item i          ON sa.cs_item_sk      = i.i_item_sk
JOIN call_center cc   ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w      ON sa.cs_warehouse_sk   = w.w_warehouse_sk
JOIN date_dim d_sold  ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN inventory inv    ON inv.inv_date_sk    = sa.cs_sold_date_sk
                       AND inv.inv_item_sk   = sa.cs_item_sk
                       AND inv.inv_warehouse_sk = sa.cs_warehouse_sk
ORDER BY i.i_category_id, sa.total_sales DESC
LIMIT 100
