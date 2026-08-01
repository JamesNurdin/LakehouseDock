WITH sampled_inventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
filtered_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        cc.cc_call_center_id,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        cr.cr_return_amount,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_paid DESC) AS yearly_sales_rank
    FROM date_dim d
    FULL OUTER JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN sampled_inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND ss.ss_sales_price > 100
      AND cr.cr_return_amount < 200
      AND inv.inv_quantity_on_hand > 500
      AND cc.cc_employees > 200
      AND ss.ss_ticket_number NOT IN (
          SELECT cr_order_number FROM catalog_returns WHERE cr_order_number IS NOT NULL
      )
)
SELECT
    d_year,
    d_month_seq,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(wr_return_amt) AS total_web_return,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_tickets,
    MAX(yearly_sales_rank) AS max_sales_rank,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount
FROM filtered_data
GROUP BY ROLLUP (d_year, d_month_seq)
ORDER BY d_year DESC, d_month_seq NULLS LAST
LIMIT 100
