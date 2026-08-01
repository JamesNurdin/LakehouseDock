WITH cs_aggr AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_net_profit,
        ARRAY[cs.cs_quantity, CAST(cs.cs_wholesale_cost AS decimal(7,2))] AS qty_cost_arr,
        (
            SELECT max(cs2.cs_list_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) AS max_item_price
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 20
      AND cs.cs_quantity BETWEEN 1 AND 10
)
SELECT
    d.d_date,
    w.w_warehouse_name,
    s.s_store_name,
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.max_item_price,
    t.qty_cost,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    SUM(cs.cs_net_profit) OVER (PARTITION BY w.w_warehouse_name) AS warehouse_total_profit
FROM cs_aggr cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
CROSS JOIN UNNEST(cs.qty_cost_arr) AS t(qty_cost)
WHERE d.d_year = 2001
  AND w.w_county = 'Mobile County'
  AND s.s_state = 'CA'
  AND sr.sr_return_quantity > 0
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk
          AND sr2.sr_return_quantity > 5
    )
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_store_sk = s.s_store_sk
          AND sr3.sr_returned_date_sk = d.d_date_sk
    )
ORDER BY w.w_warehouse_name, profit_rank
LIMIT 100
