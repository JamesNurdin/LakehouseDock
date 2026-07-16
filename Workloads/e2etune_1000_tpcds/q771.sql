WITH cs_month AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(cs.cs_net_profit) AS total_net_profit,
           AVG(cs.cs_ext_discount_amt) AS avg_discount,
           COUNT(*) AS cs_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_ext_tax > 50.00
    GROUP BY d.d_year, d.d_month_seq
),
wr_month AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(DISTINCT wr.wr_reason_sk) AS distinct_return_reasons
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
    GROUP BY d.d_year, d.d_month_seq
),
inv_month AS (
    SELECT d.d_year,
           d.d_month_seq,
           AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim d
      ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY d.d_year, d.d_month_seq
),
store_month AS (
    SELECT d.d_year,
           d.d_month_seq,
           COUNT(DISTINCT s.s_store_sk) AS stores_closed
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
    GROUP BY d.d_year, d.d_month_seq
)
SELECT cs.d_year,
       cs.d_month_seq,
       cs.total_net_profit,
       cs.avg_discount,
       cs.cs_txn_cnt,
       wr.total_return_amt,
       wr.distinct_return_reasons,
       inv.avg_inventory_qty,
       st.stores_closed
FROM cs_month cs
LEFT JOIN wr_month wr
  ON cs.d_year = wr.d_year AND cs.d_month_seq = wr.d_month_seq
LEFT JOIN inv_month inv
  ON cs.d_year = inv.d_year AND cs.d_month_seq = inv.d_month_seq
LEFT JOIN store_month st
  ON cs.d_year = st.d_year AND cs.d_month_seq = st.d_month_seq
WHERE cs.total_net_profit > 10000
ORDER BY cs.total_net_profit DESC
LIMIT 100
