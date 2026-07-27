WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_store_sk,
       ss.ss_customer_sk,
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_ext_sales_price,
       ss.ss_net_paid,
       ss.ss_net_profit,
       d.d_date,
       d.d_year,
       c.c_first_name,
       c.c_last_name,
       s.s_store_name,
       s.s_market_desc,
       ss.ss_wholesale_cost
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year BETWEEN 2001 AND 2002                     -- filter 1: year range
     AND s.s_market_desc LIKE '%financial%'                -- filter 2: market description pattern
     AND ss.ss_wholesale_cost > 30                         -- filter 3: cost threshold
),
inv_join AS (
   SELECT
       i.inv_date_sk,
       i.inv_quantity_on_hand
   FROM inventory i
),
wr_join AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_refunded_customer_sk,
       wr.wr_net_loss,
       wr.wr_return_amt
   FROM web_returns wr
)
SELECT
    b.s_store_name,
    b.d_date,
    b.c_first_name,
    b.c_last_name,
    b.ss_net_profit,
    inv.inv_quantity_on_hand,
    wr.wr_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY b.s_store_name, b.d_year
        ORDER BY b.ss_net_profit DESC
    ) AS profit_rank
FROM base b
LEFT JOIN inv_join inv
    ON inv.inv_date_sk = b.ss_sold_date_sk               -- follows inventory.inv_date_sk = date_dim.d_date_sk
LEFT JOIN wr_join wr
    ON wr.wr_returned_date_sk = b.ss_sold_date_sk
   AND wr.wr_refunded_customer_sk = b.ss_customer_sk      -- follows web_returns.wr_refunded_customer_sk = customer.c_customer_sk
WHERE inv.inv_quantity_on_hand > 0                        -- filter 4: inventory quantity
  AND wr.wr_net_loss > 0                                   -- filter 5: loss amount
  AND wr.wr_return_amt > 10                                 -- filter 6: return amount threshold
ORDER BY profit_rank ASC, b.s_store_name
LIMIT 100
