WITH sales_data AS (
    SELECT
        d.d_year,
        s.s_state,
        cp.cp_department,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv_qty.total_qty_on_date
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
        ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_qty_on_date
        FROM inventory i
        WHERE i.inv_item_sk = cs.cs_item_sk
          AND i.inv_date_sk = d.d_date_sk
    ) inv_qty
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_returned_date_sk = d.d_date_sk
      )
)
SELECT
    d_year,
    s_state,
    cp_department,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    SUM(cs_net_profit) AS total_profit,
    SUM(total_qty_on_date) AS total_inventory_qty
FROM sales_data
GROUP BY GROUPING SETS (
    (d_year, s_state, cp_department),
    (d_year, s_state),
    (d_year),
    ()
)
ORDER BY d_year DESC, s_state, cp_department
LIMIT 100
