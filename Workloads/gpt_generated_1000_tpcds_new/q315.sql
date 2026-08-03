WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk, inv_warehouse_sk
)
SELECT
    d_inv.d_date,
    w.w_warehouse_name,
    i.total_qty,
    i.distinct_items,
    st.s_store_name,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    CASE
        WHEN ss.ss_net_paid > (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS net_paid_category,
    r.r_reason_desc,
    cp.cp_catalog_page_number,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY i.total_qty DESC) AS warehouse_qty_rank,
    RANK() OVER (ORDER BY ss.ss_net_paid DESC) AS global_sales_rank
FROM inv_agg i
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_inv.d_date_sk
JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_inv.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_inv.d_date_sk
WHERE d_inv.d_year = 2001
  AND w.w_city = 'Seattle'
  AND st.s_state = 'WA'
  AND r.r_reason_id LIKE 'AAAAAAAA%'
  AND cp.cp_type = 'A'
  AND ss.ss_quantity >= 1
ORDER BY i.total_qty DESC
LIMIT 100
