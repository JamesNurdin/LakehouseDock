WITH agg_sales AS (
    SELECT
        cs_sold_time_sk,
        cs_bill_addr_sk,
        SUM(cs_net_paid)      AS total_net_paid,
        SUM(cs_quantity)     AS total_quantity
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid > 100
      AND cs_quantity > 0
    GROUP BY cs_sold_time_sk, cs_bill_addr_sk
),
returns_filtered AS (
    SELECT
        sr_return_time_sk,
        sr_store_sk,
        sr_return_amt
    FROM store_returns
    WHERE sr_return_amt > 50
      AND sr_fee < 100
      AND sr_return_ship_cost > 0
),
times_without_returns AS (
    SELECT cs_sold_time_sk AS time_sk FROM agg_sales
    EXCEPT
    SELECT sr_return_time_sk FROM store_returns WHERE sr_return_amt > 500
)
SELECT
    s.s_store_id,
    ca.ca_city,
    td.t_hour,
    agg.total_net_paid,
    agg.total_quantity,
    RANK() OVER (PARTITION BY s.s_state ORDER BY agg.total_net_paid DESC)       AS state_net_paid_rank,
    ROW_NUMBER() OVER (ORDER BY agg.total_net_paid DESC)                     AS global_rank
FROM agg_sales agg
JOIN time_dim td
    ON agg.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN returns_filtered rf
    ON rf.sr_return_time_sk = td.t_time_sk
JOIN store s
    ON rf.sr_store_sk = s.s_store_sk
WHERE td.t_sub_shift = 'morning'
  AND td.t_second > 5
  AND s.s_state = 'CA'
  AND ca.ca_zip LIKE '9%'
  AND agg.total_net_paid > 5000
  AND agg.cs_sold_time_sk IN (SELECT time_sk FROM times_without_returns)
ORDER BY agg.total_net_paid DESC
OFFSET 10 ROWS
FETCH NEXT 100 ROWS ONLY
