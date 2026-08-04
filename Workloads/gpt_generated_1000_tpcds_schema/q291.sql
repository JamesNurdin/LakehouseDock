WITH cs_agg AS (
  SELECT
    d.d_year AS year,
    cc.cc_name AS entity_name,
    i.i_item_id AS item_id,
    regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
    SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS item_desc_prefix,
    SUM(cs.cs_net_paid_inc_tax) AS total_paid,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2001
    AND regexp_like(i.i_formulation, '^\\d{4}')
    AND i.i_manufact LIKE '%stable%'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )
  GROUP BY d.d_year, cc.cc_name, i.i_item_id,
           regexp_extract(i.i_formulation, '(\\d+)', 1),
           SUBSTRING(i.i_item_desc FROM 1 FOR 10)
),

ss_agg AS (
  SELECT
    d.d_year AS year,
    s.s_store_name AS entity_name,
    i.i_item_id AS item_id,
    regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_number,
    SUBSTRING(i.i_item_desc FROM 1 FOR 10) AS item_desc_prefix,
    SUM(ss.ss_net_paid_inc_tax) AS total_paid,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
    AND i.i_manufact LIKE '%stable%'
    AND regexp_like(i.i_formulation, '^\\d{4}')
    AND NOT EXISTS (
        SELECT 1 FROM store_sales ss2
        WHERE ss2.ss_ticket_number = ss.ss_ticket_number
          AND ss2.ss_quantity > 10
    )
  GROUP BY d.d_year, s.s_store_name, i.i_item_id,
           regexp_extract(i.i_formulation, '(\\d+)', 1),
           SUBSTRING(i.i_item_desc FROM 1 FOR 10)
)

SELECT year,
       entity_name,
       item_id,
       formulation_number,
       item_desc_prefix,
       total_paid,
       sales_cnt
FROM cs_agg

UNION DISTINCT

SELECT year,
       entity_name,
       item_id,
       formulation_number,
       item_desc_prefix,
       total_paid,
       sales_cnt
FROM ss_agg

ORDER BY total_paid DESC
LIMIT 100
