WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_ticket_number,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_wholesale_cost > 10                -- predicate 1
      AND ss_list_price BETWEEN 20 AND 200      -- predicate 2
    GROUP BY ss_store_sk, ss_ticket_number
),
returns_agg AS (
    SELECT
        sr_store_sk,
        sr_ticket_number,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    WHERE sr_return_tax > 5                     -- predicate 3
      AND sr_return_quantity > 0
    GROUP BY sr_store_sk, sr_ticket_number
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_manager,
    s.s_state,
    sa.total_sales,
    ra.total_return_amt,
    (sa.total_net_profit - ra.total_net_loss) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (sa.total_net_profit - ra.total_net_loss) DESC) AS state_rank
FROM sales_agg sa
JOIN returns_agg ra
  ON sa.ss_store_sk = ra.sr_store_sk
 AND sa.ss_ticket_number = ra.sr_ticket_number
JOIN store s
  ON s.s_store_sk = sa.ss_store_sk
WHERE sa.total_sales > 1000
  AND ra.total_return_amt > 100
  AND s.s_manager = 'Matt Frederick'
ORDER BY state_rank, s.s_store_id
LIMIT 100
