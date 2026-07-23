WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE td.t_meal_time = 'dinner'
      AND hd.hd_buy_potential = '501-1000'
      AND inv.inv_quantity_on_hand > 0
),
catalog_ret AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN sales s ON cr.cr_order_number = s.cs_order_number
),
web_ret AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_refunded_cash,
        wr.wr_fee,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN sales s ON s.cs_item_sk = i.i_item_sk AND s.cs_sold_time_sk = td.t_time_sk
),
customer_agg AS (
    SELECT
        s.customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(s.cs_quantity) AS total_quantity_sold,
        COUNT(DISTINCT s.cs_item_sk) AS distinct_items_sold,
        SUM(s.cs_net_profit) AS total_net_profit,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount
    FROM sales s
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_ret cr ON cr.cr_order_number = s.cs_order_number
    LEFT JOIN web_ret wr ON wr.wr_order_number = s.cs_order_number
    GROUP BY
        s.customer_sk,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_sk,
        w.w_warehouse_name
)
SELECT
    ca.customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    ca.w_warehouse_name,
    ca.total_quantity_sold,
    ca.distinct_items_sold,
    ca.total_net_profit,
    ca.total_catalog_return_amount,
    ca.total_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ca.w_warehouse_sk ORDER BY ca.total_net_profit DESC) AS warehouse_customer_rank
FROM customer_agg ca
ORDER BY warehouse_customer_rank, ca.total_net_profit DESC
LIMIT 100
