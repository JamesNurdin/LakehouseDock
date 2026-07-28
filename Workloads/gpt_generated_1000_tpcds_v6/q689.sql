WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        w.w_warehouse_sk,
        w.w_state,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_item_sk = cs.cs_item_sk
        AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    WHERE i.i_category = 'Electronics'
      AND td.t_shift = 'first'
      AND cp.cp_department = 'Sports'
      AND ca.ca_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_catalog_number, w.w_warehouse_sk, w.w_state
),
returns_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        w.w_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE i.i_category = 'Electronics'
      AND td.t_shift = 'first'
    GROUP BY cp.cp_catalog_page_sk, w.w_warehouse_sk
)
SELECT
    sa.cp_catalog_page_sk,
    sa.cp_department,
    sa.cp_catalog_number,
    sa.w_warehouse_sk,
    sa.w_state,
    sa.total_profit,
    sa.total_sales,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    (sa.total_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns,
    RANK() OVER (
        PARTITION BY sa.cp_catalog_page_sk
        ORDER BY (sa.total_profit - COALESCE(ra.total_return_amount, 0)) DESC
    ) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.cp_catalog_page_sk = ra.cp_catalog_page_sk
    AND sa.w_warehouse_sk = ra.w_warehouse_sk
ORDER BY sa.cp_catalog_page_sk, profit_rank
LIMIT 100
