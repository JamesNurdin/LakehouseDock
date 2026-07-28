WITH sales_item AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_item_desc,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        d.d_year
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '^.*[0-9]{3}.*$')
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    substring(cp.cp_description, 1, 30) AS page_desc_snippet,
    si.i_brand,
    si.i_category,
    SUM(si.cs_quantity) AS total_qty,
    SUM(si.cs_net_paid) AS total_net_paid,
    (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_brand = si.i_brand
    ) AS avg_net_paid_by_brand,
    CASE
        WHEN regexp_like(cp.cp_type, '^promo.*') THEN 'Promo'
        ELSE 'Regular'
    END AS page_type_flag
FROM sales_item si
JOIN catalog_page cp ON si.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON si.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON si.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cp.cp_description LIKE '%Special%'
  AND ib.ib_upper_bound > 50000
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cp.cp_description,
    cp.cp_type,
    si.i_brand,
    si.i_category
ORDER BY total_net_paid DESC
LIMIT 100
