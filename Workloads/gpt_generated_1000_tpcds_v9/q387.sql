WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        i.i_brand AS item_brand,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    LEFT JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = cs.cs_ship_customer_sk
    )
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cc.cc_rec_start_date < DATE '2002-01-01'
    GROUP BY
        cc.cc_name,
        w.w_warehouse_name,
        i.i_brand,
        p.p_promo_name
)
SELECT
    call_center_name,
    warehouse_name,
    item_brand,
    promo_name,
    total_net_profit,
    total_quantity,
    distinct_orders,
    total_return_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY call_center_name ORDER BY total_net_profit DESC) AS profit_rank_per_call_center,
    SUM(total_net_profit) OVER (PARTITION BY call_center_name) AS total_profit_per_call_center
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
