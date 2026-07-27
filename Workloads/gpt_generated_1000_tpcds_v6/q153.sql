WITH filtered_web_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_paid_inc_tax,
        d_ws.d_year
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE ws.ws_net_paid_inc_tax > 1000
      AND d_ws.d_year BETWEEN 2000 AND 2002
      AND EXISTS (
          SELECT 1 FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_type = 'Content'
      )
)
SELECT
    d_sold.d_year,
    cp.cp_department,
    cd.cd_gender,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    (
        SELECT SUM(fws.ws_net_paid_inc_tax)
        FROM filtered_web_sales fws
        WHERE fws.d_year = d_sold.d_year
    ) AS total_web_sales,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS sales_rank
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cp.cp_department IN (
        SELECT DISTINCT cp_department
        FROM catalog_page
        WHERE cp_type = 'Catalog'
      )
  AND d_sold.d_month_seq >= 1200
  AND cs.cs_quantity > 1
  AND cs.cs_ext_discount_amt < 500
  AND cd.cd_education_status = 'College'
GROUP BY d_sold.d_year, cp.cp_department, cd.cd_gender
ORDER BY d_sold.d_year DESC, sales_rank
LIMIT 100
