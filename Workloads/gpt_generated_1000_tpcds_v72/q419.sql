WITH filtered_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_net_profit,
       cs.cs_quantity,
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       i.i_formulation,
       i.i_category,
       ca.ca_city,
       ca.ca_state,
       cc.cc_name,
       cp.cp_catalog_number,
       cp.cp_catalog_page_number,
       cp.cp_description
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE regexp_like(i.i_formulation, '[0-9]{2}[a-z]+[0-9]{3}')
     AND ca.ca_city LIKE '%Ville%'
     AND cc.cc_name LIKE '%Center%'
),

avg_profit_by_category AS (
   SELECT
       i_category,
       AVG(cs_net_profit) AS avg_category_profit
   FROM filtered_sales
   GROUP BY i_category
)

SELECT
    fs.i_item_id,
    fs.i_product_name,
    substring(fs.i_formulation, 1, 10) AS formulation_prefix,
    fs.ca_city,
    fs.ca_state,
    sum(fs.cs_quantity) AS total_quantity,
    sum(fs.cs_net_profit) AS total_net_profit,
    avgp.avg_category_profit,
    concat('Category_', fs.i_category) AS category_label,
    regexp_extract(fs.cp_description, '(\\d+)', 1) AS description_number,
    (SELECT count(*) FROM promotion p WHERE p.p_item_sk = fs.i_item_sk) AS promo_count
FROM filtered_sales fs
JOIN avg_profit_by_category avgp
  ON fs.i_category = avgp.i_category
WHERE fs.cs_net_profit > avgp.avg_category_profit
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = fs.i_item_sk
          AND p.p_discount_active = 'Y'
      )
GROUP BY
    fs.i_item_id,
    fs.i_product_name,
    substring(fs.i_formulation, 1, 10),
    fs.ca_city,
    fs.ca_state,
    avgp.avg_category_profit,
    concat('Category_', fs.i_category),
    regexp_extract(fs.cp_description, '(\\d+)', 1),
    fs.i_category,
    fs.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
