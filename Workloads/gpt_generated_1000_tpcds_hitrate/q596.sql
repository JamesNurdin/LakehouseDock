WITH
    -- Aggregate sales per item, store and sale date
    sales_agg AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_quantity) AS total_qty
        FROM store_sales ss
        GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    -- Customers who bought something
    buyers AS (
        SELECT DISTINCT ss.ss_customer_sk AS cust_sk
        FROM store_sales ss
    ),
    -- Customers who returned something
    returners AS (
        SELECT DISTINCT sr.sr_customer_sk AS cust_sk
        FROM store_returns sr
    ),
    -- Buyers who never returned (EXCEPT)
    pure_buyers AS (
        SELECT cust_sk FROM buyers
        EXCEPT
        SELECT cust_sk FROM returners
    ),
    -- Buyers born after 1960
    young_buyers AS (
        SELECT c.c_customer_sk AS cust_sk
        FROM customer c
        WHERE c.c_birth_year > 1960
    ),
    -- Intersection of the two sets (INTERSECT)
    target_customers AS (
        SELECT cust_sk FROM pure_buyers
        INTERSECT
        SELECT cust_sk FROM young_buyers
    ),
    -- Average price of all items (scalar subquery source)
    avg_item_price AS (
        SELECT AVG(i_current_price) AS avg_price FROM item
    )
SELECT
    s.s_store_name,
    i.i_product_name,
    ds.d_year,
    sa.total_sales,
    sa.total_qty,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(p.p_cost) AS avg_promo_cost,
    (SELECT avg_price FROM avg_item_price) AS overall_avg_price
FROM sales_agg sa
JOIN date_dim ds
    ON ds.d_date_sk = sa.ss_sold_date_sk                                 -- join 1
JOIN item i
    ON i.i_item_sk = sa.ss_item_sk                                        -- join 2
JOIN store s
    ON s.s_store_sk = sa.ss_store_sk                                      -- join 3
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk                                          -- join 4
JOIN date_dim p_date
    ON p_date.d_date_sk = p.p_start_date_sk                                -- join 5
JOIN store_sales ss_detail
    ON ss_detail.ss_item_sk = sa.ss_item_sk
   AND ss_detail.ss_store_sk = sa.ss_store_sk
   AND ss_detail.ss_sold_date_sk = sa.ss_sold_date_sk                       -- join 6
JOIN customer c
    ON c.c_customer_sk = ss_detail.ss_customer_sk                         -- join 7
JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk                              -- join 8
JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk                                 -- join 9
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk                                 -- join 10
WHERE c.c_customer_sk IN (SELECT cust_sk FROM target_customers)            -- IN uncorrelated subquery
  AND s.s_store_id IN (
        SELECT DISTINCT s2.s_store_id
        FROM store s2
        WHERE s2.s_number_employees > 200
    )                                                                       -- filter with IN subquery
GROUP BY
    s.s_store_name,
    i.i_product_name,
    ds.d_year,
    sa.total_sales,
    sa.total_qty
HAVING
    sa.total_sales > 10000
    AND COUNT(DISTINCT c.c_customer_sk) >= 5
ORDER BY sa.total_sales DESC
LIMIT 100
