WITH date_q1 AS (
    SELECT d_date_sk,
           d_quarter_name,
           d_year
    FROM tpcds.date_dim
    WHERE d_year = 2002
      AND d_quarter_name LIKE 'Q1%'
),
returns_agg AS (
    SELECT d.d_quarter_name,
           SUM(sr.sr_return_amt) AS total_return_amt,
           AVG(sr.sr_return_tax) AS avg_return_tax
    FROM date_q1 d
    JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_quarter_name
),
inventory_agg AS (
    SELECT d.d_quarter_name,
           w.w_warehouse_sk,
           w.w_warehouse_name,
           regexp_extract(w.w_warehouse_id, '(\\d+)$', 1) AS warehouse_id_suffix,
           SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM date_q1 d
    JOIN tpcds.inventory i
      ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(w.w_warehouse_name, '^.*[0-9]{3}$')
    GROUP BY d.d_quarter_name,
             w.w_warehouse_sk,
             w.w_warehouse_name,
             w.w_warehouse_id
)
SELECT concat('Quarter ', ra.d_quarter_name) AS quarter_label,
       ia.w_warehouse_name,
       ia.warehouse_id_suffix,
       ra.total_return_amt,
       ra.avg_return_tax,
       ia.total_qty_on_hand
FROM returns_agg ra
JOIN inventory_agg ia
  ON ra.d_quarter_name = ia.d_quarter_name
ORDER BY quarter_label, ia.w_warehouse_name
LIMIT 100
