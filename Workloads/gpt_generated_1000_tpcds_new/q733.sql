WITH sampled_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE ss_coupon_amt > 1000
),
filtered_returns AS (
   SELECT *
   FROM store_returns
   WHERE regexp_like(cast(sr_store_credit AS varchar), '^\\d+\\.\\d{2}$')
     AND cast(sr_hdemo_sk AS varchar) LIKE '4%'
),
common_items AS (
   SELECT sr_item_sk AS item_sk FROM filtered_returns
   INTERSECT
   SELECT ss_item_sk FROM sampled_sales
),
joined_returns_sales AS (
   SELECT
       sr.sr_item_sk AS item_sk,
       sr.sr_return_quantity AS quantity,
       sr.sr_return_amt AS amount,
       concat('RET_', cast(sr.sr_ticket_number AS varchar)) AS ticket_code
   FROM filtered_returns sr
   JOIN sampled_sales ss
       ON sr.sr_item_sk = ss.ss_item_sk
),
union_data AS (
   SELECT item_sk, quantity, amount, ticket_code FROM joined_returns_sales
   UNION
   SELECT
       ss_item_sk AS item_sk,
       ss_quantity AS quantity,
       ss_sales_price AS amount,
       concat('SAL_', cast(ss_ticket_number AS varchar)) AS ticket_code
   FROM sampled_sales
   WHERE ss_item_sk IN (SELECT item_sk FROM common_items)
)
SELECT
   item_sk,
   sum(quantity) AS total_quantity,
   sum(amount)   AS total_amount,
   count(DISTINCT ticket_code)               AS distinct_tickets,
   count(DISTINCT substring(ticket_code, 1, 3)) AS distinct_prefixes
FROM union_data
GROUP BY item_sk
ORDER BY total_amount DESC
LIMIT 100
