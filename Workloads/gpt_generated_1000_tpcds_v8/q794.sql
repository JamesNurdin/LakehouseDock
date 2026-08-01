WITH
  -- Items that were sold but never returned
  sold_items AS (
    SELECT ss_item_sk AS i_item_sk
    FROM store_sales
  ),
  returned_items AS (
    SELECT sr_item_sk AS i_item_sk
    FROM store_returns
  ),
  items_sold_not_returned AS (
    SELECT i_item_sk
    FROM sold_items
    EXCEPT
    SELECT i_item_sk
    FROM returned_items
  ),

  -- Customers that both bought something and have a web page record
  customers_with_sales AS (
    SELECT DISTINCT ss_customer_sk AS c_customer_sk
    FROM store_sales
  ),
  customers_with_web AS (
    SELECT DISTINCT wp_customer_sk AS c_customer_sk
    FROM web_page
  ),
  customers_both AS (
    SELECT c_customer_sk
    FROM customers_with_sales
    INTERSECT
    SELECT c_customer_sk
    FROM customers_with_web
  ),

  -- Full outer join of sales and returns on ticket number
  full_sales_returns AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_customer_sk AS r_customer_sk,
      sr.sr_ticket_number
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
  ),

  -- Aggregation with string processing and distinct aggregates
  agg_data AS (
    SELECT
      COALESCE(f.ss_customer_sk, f.r_customer_sk) AS customer_sk,
      i.i_brand,
      i.i_units,
      SUM(COALESCE(f.ss_ext_sales_price, 0)) AS total_sales,
      SUM(COALESCE(f.sr_return_amt, 0)) AS total_returns,
      COUNT(DISTINCT f.ss_item_sk) AS distinct_items_sold,
      COUNT(DISTINCT i.i_brand) AS distinct_brands,
      CASE WHEN nr.i_item_sk IS NOT NULL THEN true ELSE false END AS never_returned_flag
    FROM full_sales_returns f
    JOIN item i
      ON f.ss_item_sk = i.i_item_sk
    LEFT JOIN items_sold_not_returned nr
      ON nr.i_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_formulation, '^[0-9]{3}')
      AND i.i_units LIKE '%e%'
    GROUP BY
      COALESCE(f.ss_customer_sk, f.r_customer_sk),
      i.i_brand,
      i.i_units,
      nr.i_item_sk
    HAVING SUM(COALESCE(f.ss_ext_sales_price, 0)) > 1000
  )
SELECT
  c.c_customer_id,
  a.i_brand,
  a.i_units,
  a.total_sales,
  a.total_returns,
  a.distinct_items_sold,
  a.distinct_brands,
  a.never_returned_flag,
  -- Correlated scalar subquery: total sales of this customer for the same brand across all dates
  (SELECT SUM(ss2.ss_ext_sales_price)
     FROM store_sales ss2
     JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
    WHERE ss2.ss_customer_sk = a.customer_sk
      AND i2.i_brand = a.i_brand) AS customer_brand_total_sales,
  -- Presence flag based on INTERSECT set
  CASE WHEN EXISTS (
         SELECT 1 FROM customers_both cb WHERE cb.c_customer_sk = a.customer_sk)
       THEN 'BothSalesAndWeb'
       ELSE 'OnlyOneSide'
  END AS customer_presence
FROM agg_data a
JOIN customer c ON a.customer_sk = c.c_customer_sk
WHERE EXISTS (
        SELECT 1
          FROM web_page wp
         WHERE wp.wp_customer_sk = c.c_customer_sk
           AND wp.wp_image_count > (
                 SELECT AVG(wp2.wp_image_count)
                   FROM web_page wp2)
      )
ORDER BY a.total_sales DESC
LIMIT 100
