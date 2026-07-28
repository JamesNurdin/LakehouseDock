/*
  Goal: Analyze high‑value store returns by brand and product for reasons containing the word "better". 
  The query filters to items whose product name includes "Pro", extracts the relevant portion of the reason text, computes total, count, and average return amounts per brand‑product, ranks brands by total return amount, and limits the result to the top 100 rows.
*/
WITH filtered_returns AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_item_sk,
        i.i_brand,
        i.i_product_name,
        r.r_reason_desc,
        r.r_reason_sk,
        t.t_time_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)better')
      AND i.i_product_name LIKE '%Pro%'
)
SELECT
    concat(i_brand, ' - ', i_product_name)                                 AS brand_product,
    r_reason_desc                                                         AS reason_desc,
    substring(i_product_name, 1, 10)                                      AS product_prefix,
    regexp_extract(r_reason_desc, '(better.*)', 1)                        AS better_phrase,
    SUM(sr_return_amt)                                                    AS total_return_amt,
    COUNT(*)                                                              AS return_cnt,
    AVG(sr_return_amt)                                                    AS avg_return_amt,
    RANK() OVER (PARTITION BY i_brand ORDER BY SUM(sr_return_amt) DESC)   AS brand_return_rank
FROM filtered_returns fr
JOIN (
    SELECT
        sr2.sr_item_sk,
        AVG(sr2.sr_return_amt) AS item_avg_return_amt
    FROM store_returns sr2
    GROUP BY sr2.sr_item_sk
) avg_per_item
  ON fr.sr_item_sk = avg_per_item.sr_item_sk
WHERE fr.sr_return_amt > avg_per_item.item_avg_return_amt
GROUP BY
    i_brand,
    i_product_name,
    r_reason_desc,
    substring(i_product_name, 1, 10),
    regexp_extract(r_reason_desc, '(better.*)', 1)
HAVING SUM(sr_return_amt) > 1000
ORDER BY total_return_amt DESC, brand_product
LIMIT 100
