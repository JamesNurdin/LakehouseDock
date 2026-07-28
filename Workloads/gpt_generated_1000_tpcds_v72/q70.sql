WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d_sold.d_year AS d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON cs.cs_item_sk = inv.inv_item_sk
        AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
        AND cs.cs_sold_date_sk = inv.inv_date_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_current_price BETWEEN 5 AND 30
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name, d_sold.d_year
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    total_net_paid,
    total_net_profit,
    sales_cnt,
    avg_sales_price,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rn_yearly_sales,
    RANK() OVER (ORDER BY total_net_profit DESC) AS rank_global_profit
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
