/*
Goal: Identify the most profitable product categories per year for the years 2001‑2002, using only items whose names match a specific pattern, enriched with string‑processing logic, a scalar subquery, CASE logic, and a HAVING filter.
*/
WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_product_name
    FROM tpcds.item i
    WHERE i.i_product_name LIKE '%PROD%'
      AND regexp_like(i.i_product_name, '[A-Z]{2,}[0-9]{3}')
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs
          WHERE cs.cs_item_sk = i.i_item_sk
            AND cs.cs_net_paid_inc_ship_tax > 20000
      )
)
SELECT
    fi.i_category,
    d.d_year,
    concat(fi.i_category, '-', cast(d.d_year AS varchar)) AS cat_year,
    sum(ss.ss_net_paid) AS total_sales,
    sum(coalesce(sr.sr_net_loss, 0)) AS total_return_loss,
    case
        when sum(ss.ss_net_paid) - sum(coalesce(sr.sr_net_loss, 0)) > 50000 then 'Profitable'
        else 'Marginal'
    end AS profitability,
    count(distinct ss.ss_ticket_number) AS num_transactions,
    substring(fi.i_product_name, 1, 10) AS product_prefix,
    case
        when regexp_like(fi.i_product_name, '\\d{3}') then 'HasDigits'
        else 'NoDigits'
    end AS digit_flag
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE d.d_year BETWEEN 2001 AND 2002
GROUP BY fi.i_category, d.d_year, fi.i_product_name
HAVING sum(ss.ss_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
