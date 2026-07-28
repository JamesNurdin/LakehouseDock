WITH item_sales AS (
   SELECT
       i.i_item_id,
       i.i_brand,
       p.p_promo_name,
       w.w_warehouse_name,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_loss,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
       CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
   WHERE i.i_current_price BETWEEN 10 AND 100
     AND p.p_channel_details LIKE '%family%'
     AND (w.w_county = 'Oglethorpe County' OR w.w_county IS NULL)
   GROUP BY i.i_item_id, i.i_brand, p.p_promo_name, w.w_warehouse_name
),
brand_rank AS (
   SELECT
       i_brand,
       AVG(total_sales) AS avg_sales,
       AVG(total_loss) AS avg_loss,
       COUNT(*) AS item_cnt,
       RANK() OVER (ORDER BY AVG(total_sales) DESC) AS sales_rank
   FROM item_sales
   GROUP BY i_brand
)
SELECT DISTINCT
   br.i_brand,
   br.avg_sales,
   br.avg_loss,
   br.item_cnt,
   br.sales_rank,
   (SELECT COUNT(DISTINCT i_item_id) FROM item_sales) AS distinct_items,
   (SELECT MAX(total_sales) FROM item_sales) AS max_total_sales,
   CASE WHEN br.sales_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_category
FROM brand_rank br
WHERE br.avg_sales > 1000
  AND br.item_cnt >= 10
  AND br.sales_rank <= 20
ORDER BY br.avg_sales DESC
LIMIT 100
