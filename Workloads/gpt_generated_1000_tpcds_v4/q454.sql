WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_sold_date_sk,
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        c.c_customer_id,
        c.c_birth_country,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{2}[0-9]{3}\\b')   -- e.g., codes like AB123
      AND c.c_birth_country LIKE 'C%'                           -- countries starting with C
),
avg_sales AS (
    SELECT avg(cs_ext_sales_price) AS avg_price FROM catalog_sales
)
SELECT
    sf.d_year,
    sf.d_month_seq,
    sf.i_item_id,
    sf.i_item_desc,
    sf.c_customer_id,
    sf.c_birth_country,
    SUM(sf.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(sf.cs_ext_sales_price) > (SELECT avg_price FROM avg_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY sf.d_year, sf.d_month_seq ORDER BY SUM(sf.cs_ext_sales_price) DESC) AS sales_rank,
    concat(sf.i_item_id, '-', substr(sf.c_birth_country, 1, 3)) AS item_country_key
FROM sales_filtered sf
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE sr.sr_item_sk = sf.i_item_sk
      AND dr.d_year = sf.d_year
)
GROUP BY
    sf.d_year,
    sf.d_month_seq,
    sf.i_item_id,
    sf.i_item_desc,
    sf.c_customer_id,
    sf.c_birth_country,
    sf.i_item_id,
    sf.c_birth_country
HAVING COUNT(*) > 5
ORDER BY sf.d_year, sf.d_month_seq, total_sales DESC
LIMIT 100
