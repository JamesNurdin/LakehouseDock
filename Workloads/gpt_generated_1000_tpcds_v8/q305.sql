WITH sales_agg AS (
   SELECT
       cp.cp_catalog_page_sk,
       sum(cs.cs_net_profit) AS total_net_profit
   FROM catalog_page cp
   JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cs.cs_ext_tax > 0
   GROUP BY cp.cp_catalog_page_sk
),
returns_agg AS (
   SELECT
       cp.cp_catalog_page_sk,
       sum(cr.cr_net_loss) AS total_net_loss
   FROM catalog_page cp
   JOIN catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cr.cr_reversed_charge > 100
   GROUP BY cp.cp_catalog_page_sk
)
SELECT cp_page_id, cp_type, net_amount
FROM (
   SELECT
       cp.cp_catalog_page_id AS cp_page_id,
       cp.cp_type,
       sales_agg.total_net_profit AS net_amount
   FROM catalog_page cp
   JOIN sales_agg ON sales_agg.cp_catalog_page_sk = cp.cp_catalog_page_sk
   CROSS JOIN LATERAL (
        SELECT count(DISTINCT cs_inner.cs_item_sk) AS cnt
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_catalog_page_sk = cp.cp_catalog_page_sk
   ) lc
   WHERE sales_agg.total_net_profit > (SELECT avg(cs.cs_net_profit) FROM catalog_sales cs)
   UNION
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_type,
       -returns_agg.total_net_loss AS net_amount
   FROM catalog_page cp
   JOIN returns_agg ON returns_agg.cp_catalog_page_sk = cp.cp_catalog_page_sk
   CROSS JOIN LATERAL (
        SELECT count(DISTINCT cr_inner.cr_item_sk) AS cnt
        FROM catalog_returns cr_inner
        WHERE cr_inner.cr_catalog_page_sk = cp.cp_catalog_page_sk
   ) lc
   WHERE returns_agg.total_net_loss > 1000
) AS combined
EXCEPT
SELECT cp_page_id, cp_type, net_amount
FROM (
   SELECT
       cp.cp_catalog_page_id AS cp_page_id,
       cp.cp_type,
       sales_agg.total_net_profit AS net_amount
   FROM catalog_page cp
   JOIN sales_agg ON sales_agg.cp_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
          AND cr.cr_reversed_charge > 500
   )
) AS exclude_set
ORDER BY net_amount DESC
LIMIT 100
