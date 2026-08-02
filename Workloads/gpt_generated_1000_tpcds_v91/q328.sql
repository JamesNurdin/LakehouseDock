WITH sales_base AS (
    SELECT
        i.i_category AS category,
        cp.cp_department AS department,
        CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        SUM(cs.cs_net_profit) AS sum_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_name
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        LIMIT 1
    ) p
    FULL OUTER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    LEFT JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
    WHERE
        cp.cp_department = 'Sports'
        AND i.i_current_price > 100
        AND sm.sm_contract = '2mM8l'
        AND w.w_state = 'CA'
        AND c_bill.c_birth_country IN ('BHUTAN', 'BAHRAIN')
        AND cs.cs_quantity > 5
        AND cs.cs_net_paid > 0
    GROUP BY
        i.i_category,
        cp.cp_department,
        CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END
)
SELECT
    profit_flag,
    SUM(order_cnt) AS total_orders,
    SUM(sum_net_paid) AS total_paid,
    AVG(sum_net_profit) AS avg_profit,
    SUM(CASE WHEN profit_flag = 'PROFIT' THEN sum_net_profit ELSE 0 END) AS total_profit_from_profit_flag
FROM sales_base
GROUP BY profit_flag
HAVING SUM(order_cnt) > 10
ORDER BY total_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
