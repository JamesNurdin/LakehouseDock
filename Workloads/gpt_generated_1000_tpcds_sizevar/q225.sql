/*
  Goal: Compute total net profit and transaction count for sales in the year 2001, broken down by store division and item category. The query filters items whose description contains the word "brand" (case‑insensitive) and stores whose name contains "Market". It also extracts numeric promo codes from promotion names. Results include subtotals per division, per category, and a grand total using GROUP BY ROLLUP, and the output is ordered by division and category.
*/
WITH sales_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_division_id AS s_division_id,
    i.i_category AS i_category,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_count,
    MAX(substring(s.s_store_name, 1, 5)) AS store_name_prefix,
    MAX(substring(c.c_first_name, 1, 3)) AS customer_name_prefix,
    MAX(regexp_extract(p.p_promo_name, '([0-9]+)', 1)) AS promo_code
FROM
    sales_sample ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
WHERE
    d.d_year = 2001
    AND regexp_like(i.i_item_desc, '(?i)brand')
    AND s.s_store_name LIKE '%Market%'
    AND regexp_extract(p.p_promo_name, '([0-9]+)', 1) IS NOT NULL
GROUP BY
    ROLLUP (s.s_division_id, i.i_category)
ORDER BY
    s.s_division_id,
    i.i_category
