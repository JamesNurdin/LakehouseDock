WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cp.cp_catalog_page_id,
        cp.cp_description,
        sm.sm_ship_mode_id,
        cd.cd_credit_rating,
        ca.ca_city
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '(?i)promo')
      AND cd.cd_credit_rating = 'High Risk'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = cs.cs_order_number
            AND wr.wr_return_amt > 100
      )
)
SELECT
    fs.cp_catalog_page_id AS catalog_page,
    fs.sm_ship_mode_id AS ship_mode,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(fs.cs_ext_sales_price) > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category,
    SUBSTRING(fs.ca_city, 1, 3) AS city_prefix,
    CONCAT(fs.cp_description, ' | ', fs.sm_ship_mode_id) AS page_ship_desc
FROM filtered_sales fs
GROUP BY
    fs.cp_catalog_page_id,
    fs.sm_ship_mode_id,
    SUBSTRING(fs.ca_city, 1, 3),
    fs.cp_description,
    fs.sm_ship_mode_id
ORDER BY total_sales DESC
LIMIT 100
