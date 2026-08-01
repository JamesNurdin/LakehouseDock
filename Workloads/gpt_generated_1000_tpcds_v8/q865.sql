/*
goal: Identify words from item descriptions that appear in both profitable and loss-making sales transactions, after combining sales and returns with a full outer join, expanding the description into words, and deduplicating via UNION and INTERSECT.
*/
WITH
full_join AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_net_paid,
    sr.sr_returned_date_sk,
    sr.sr_return_amt,
    CASE WHEN ss.ss_net_paid > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
  FROM store_sales ss
  FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
),
expanded_items AS (
  SELECT
    fj.ss_sold_date_sk,
    fj.ss_item_sk,
    word,
    fj.profit_flag
  FROM full_join fj
  JOIN item i ON fj.ss_item_sk = i.i_item_sk
  CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
),
union_part AS (
  SELECT DISTINCT
    ei.ss_sold_date_sk AS date_sk,
    ei.word,
    ei.profit_flag,
    COUNT(*) OVER (PARTITION BY ei.word) AS word_occurrences
  FROM expanded_items ei
  WHERE ei.profit_flag = 'Profit'
  UNION
  SELECT DISTINCT
    ei.ss_sold_date_sk,
    ei.word,
    ei.profit_flag,
    COUNT(*) OVER (PARTITION BY ei.word) AS word_occurrences
  FROM expanded_items ei
  WHERE ei.profit_flag = 'Loss'
),
intersect_keys AS (
  SELECT date_sk FROM union_part WHERE profit_flag = 'Profit'
  INTERSECT
  SELECT date_sk FROM union_part WHERE profit_flag = 'Loss'
)
SELECT
  up.date_sk,
  up.word,
  up.profit_flag,
  up.word_occurrences
FROM union_part up
WHERE up.date_sk IN (SELECT date_sk FROM intersect_keys)
ORDER BY up.date_sk DESC, up.word
LIMIT 100
