WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        w.w_warehouse_name,
        ca_bill.ca_state,
        t_sales.t_hour,
        SUM(cs.cs_ext_sales_price)               AS total_sales,
        SUM(cs.cs_net_profit)                    AS total_profit,
        COALESCE(SUM(cr.cr_return_amount), 0)    AS total_catalog_return,
        COALESCE(SUM(sr.sr_return_amt), 0)      AS total_store_return
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_sales
        ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    LEFT JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    LEFT JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
        AND sr.sr_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN time_dim t_store_return
        ON sr.sr_return_time_sk = t_store_return.t_time_sk
    WHERE cp.cp_start_date_sk >= 2450845
      AND i.i_current_price > 100
      AND w.w_state = 'CA'
      AND t_sales.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_item_sk = i.i_item_sk
            AND cr2.cr_return_amount > 0
      )
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        w.w_warehouse_name,
        ca_bill.ca_state,
        t_sales.t_hour
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.cp_department,
    sa.w_warehouse_name,
    sa.ca_state,
    sa.t_hour,
    sa.total_sales,
    sa.total_profit,
    sa.total_catalog_return,
    sa.total_store_return,
    (
        SELECT AVG(cs2.cs_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = sa.i_item_sk
    ) AS avg_sales_price,
    RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_profit DESC) AS dept_profit_rank
FROM sales_agg sa
ORDER BY sa.total_profit DESC
LIMIT 100
