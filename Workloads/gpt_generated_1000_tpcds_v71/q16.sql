WITH sales_returns_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        cp.cp_department,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE w.w_state IN ('GA', 'NY')
      AND i.i_wholesale_cost > 1.00
      AND d.d_fy_quarter_seq = 3
    GROUP BY w.w_warehouse_id, w.w_state, cp.cp_department, d.d_year
)
SELECT
    department,
    AVG(total_profit) AS avg_profit_per_warehouse,
    SUM(total_return_amount) AS total_returns
FROM (
    SELECT
        cp_department AS department,
        total_profit,
        total_return_amount
    FROM sales_returns_agg
) agg
GROUP BY department
HAVING AVG(total_profit) > 0
ORDER BY avg_profit_per_warehouse DESC
LIMIT 100
