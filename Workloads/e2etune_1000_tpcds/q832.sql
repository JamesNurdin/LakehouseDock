WITH page_sales AS (
  SELECT
    cp.cp_department AS cp_department,
    cp.cp_catalog_number AS cp_catalog_number,
    cp.cp_catalog_page_number AS cp_catalog_page_number,
    ca.ca_state AS ca_state,
    cd.cd_gender AS cd_gender,
    p.p_promo_name AS p_promo_name,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_sales_price) AS avg_sales_price
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_start_date_sk BETWEEN 2450900 AND 2451088
    AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451088
    AND p.p_channel_tv = 'Y'
    AND ca.ca_country = 'United States'
    AND cd.cd_education_status = 'College'
  GROUP BY cp.cp_department, cp.cp_catalog_number, cp.cp_catalog_page_number,
           ca.ca_state, cd.cd_gender, p.p_promo_name
  HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
  t.cp_department,
  t.cp_catalog_number,
  t.cp_catalog_page_number,
  t.ca_state,
  t.cd_gender,
  t.p_promo_name,
  t.total_profit,
  t.total_quantity,
  t.avg_sales_price,
  t.dept_rank
FROM (
  SELECT
    ps.*, 
    ROW_NUMBER() OVER (PARTITION BY ps.cp_department ORDER BY ps.total_profit DESC) AS dept_rank
  FROM page_sales ps
) t
WHERE t.dept_rank <= 5
ORDER BY t.total_profit DESC
LIMIT 10
