WITH item_sales AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_item_sk,
    i.i_item_desc,
    i.i_product_name,
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
    AND i.i_product_name LIKE '%Deluxe%'
),
store_agg AS (
  SELECT
    isales.s_store_sk,
    isales.s_store_name,
    isales.s_city,
    sum(isales.ss_ext_sales_price) AS total_sales,
    sum(isales.ss_net_profit) AS total_profit,
    avg(
      CASE
        WHEN isales.ss_quantity > 10 THEN isales.ss_ext_sales_price * 0.9
        ELSE isales.ss_ext_sales_price
      END
    ) AS avg_adj_sales
  FROM item_sales isales
  WHERE isales.ss_ticket_number NOT IN (
    SELECT sr2.sr_ticket_number
    FROM store_returns sr2
    WHERE sr2.sr_net_loss > 0
  )
  AND EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_ticket_number = isales.ss_ticket_number
      AND r.r_reason_desc LIKE '%Damaged%'
  )
  GROUP BY isales.s_store_sk, isales.s_store_name, isales.s_city
  HAVING sum(isales.ss_ext_sales_price) > 1000
)
SELECT
  sa.s_store_sk,
  concat(sa.s_store_name, ' - ', sa.s_city) AS store_location,
  sa.total_sales,
  sa.total_profit,
  sa.avg_adj_sales,
  rank() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
  (SELECT avg(sr.sr_net_loss)
   FROM store_returns sr
   WHERE sr.sr_store_sk = sa.s_store_sk) AS avg_store_return_loss,
  CASE
    WHEN sa.total_profit > 0 THEN 'POSITIVE'
    ELSE 'NON-POSITIVE'
  END AS profit_flag
FROM store_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
