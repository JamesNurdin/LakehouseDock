WITH sales_union AS (
   SELECT 'store' AS channel,
          ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_store_sk AS store_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_quantity AS quantity,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit,
          CAST(NULL AS integer) AS ws_web_page_sk,
          CAST(NULL AS integer) AS cs_call_center_sk,
          ss.ss_ticket_number AS ticket_number,
          ss.ss_promo_sk AS promo_sk
   FROM store_sales ss
   WHERE ss.ss_sold_date_sk IS NOT NULL
   UNION ALL
   SELECT 'web' AS channel,
          ws.ws_sold_date_sk,
          ws.ws_item_sk,
          CAST(NULL AS integer),
          ws.ws_bill_customer_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_net_profit,
          ws.ws_web_page_sk,
          CAST(NULL AS integer),
          ws.ws_order_number,
          ws.ws_promo_sk
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk IS NOT NULL
   UNION ALL
   SELECT 'catalog' AS channel,
          cs.cs_sold_date_sk,
          cs.cs_item_sk,
          CAST(NULL AS integer),
          cs.cs_bill_customer_sk,
          cs.cs_quantity,
          cs.cs_net_paid,
          cs.cs_net_profit,
          CAST(NULL AS integer),
          cs.cs_call_center_sk,
          cs.cs_order_number,
          cs.cs_promo_sk
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk IS NOT NULL
),
returns_union AS (
   SELECT 'store' AS channel,
          sr.sr_returned_date_sk AS date_sk,
          sr.sr_item_sk AS item_sk,
          sr.sr_store_sk AS store_sk,
          sr.sr_customer_sk AS customer_sk,
          sr.sr_return_quantity AS quantity,
          sr.sr_return_amt AS amount,
          sr.sr_net_loss AS net_loss,
          CAST(NULL AS integer) AS ws_web_page_sk,
          CAST(NULL AS integer) AS cs_call_center_sk,
          sr.sr_ticket_number AS ticket_number
   FROM store_returns sr
   UNION ALL
   SELECT 'web' AS channel,
          wr.wr_returned_date_sk,
          wr.wr_item_sk,
          CAST(NULL AS integer),
          wr.wr_refunded_customer_sk,
          wr.wr_return_quantity,
          wr.wr_return_amt,
          wr.wr_net_loss,
          wr.wr_web_page_sk,
          CAST(NULL AS integer),
          wr.wr_order_number
   FROM web_returns wr
   UNION ALL
   SELECT 'catalog' AS channel,
          cr.cr_returned_date_sk,
          cr.cr_item_sk,
          CAST(NULL AS integer),
          cr.cr_refunded_customer_sk,
          cr.cr_return_quantity,
          cr.cr_return_amount,
          cr.cr_net_loss,
          CAST(NULL AS integer),
          cr.cr_call_center_sk,
          cr.cr_order_number
   FROM catalog_returns cr
),
sales_with_returns AS (
   SELECT s.channel,
          s.date_sk,
          d.d_date AS sale_date,
          s.item_sk,
          i.i_product_name,
          i.i_category,
          i.i_brand,
          COALESCE(s.store_sk, 0) AS store_id,
          COALESCE(s.ws_web_page_sk, 0) AS web_page_id,
          COALESCE(s.cs_call_center_sk, 0) AS call_center_id,
          s.customer_sk,
          s.quantity,
          s.net_paid,
          s.net_profit,
          COALESCE(r.quantity, 0) AS return_quantity,
          COALESCE(r.amount, 0) AS return_amount,
          COALESCE(r.net_loss, 0) AS return_net_loss,
          s.net_paid - COALESCE(r.amount, 0) AS net_after_returns,
          ROW_NUMBER() OVER (PARTITION BY s.channel, s.item_sk ORDER BY s.date_sk DESC) AS rn_item_latest_sale,
          SUM(s.net_paid) OVER (PARTITION BY s.channel) AS total_channel_net,
          CASE WHEN s.net_paid > 0 THEN s.net_paid / NULLIF(s.quantity, 0) ELSE 0 END AS avg_price_per_unit,
          CASE
              WHEN r.quantity IS NULL THEN 'No Return'
              WHEN r.quantity > 0 THEN 'Returned'
              ELSE 'Partial Return'
          END AS return_status,
          CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
          COALESCE(
               (SELECT p.p_discount_active
                FROM promotion p
                WHERE p.p_item_sk = s.item_sk
                  AND p.p_start_date_sk <= s.date_sk
                  AND p.p_end_date_sk >= s.date_sk
                ORDER BY p.p_cost DESC
                LIMIT 1),
               'N') AS promo_active_flag
   FROM sales_union s
   LEFT JOIN returns_union r
          ON s.channel = r.channel
         AND s.item_sk = r.item_sk
         AND s.date_sk = r.date_sk
   LEFT JOIN date_dim d
          ON s.date_sk = d.d_date_sk
   LEFT JOIN item i
          ON s.item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND (i.i_category = 'Electronics' OR i.i_category = 'Furniture')
),
agg AS (
   SELECT channel,
          store_id,
          web_page_id,
          call_center_id,
          SUM(net_after_returns) AS total_net,
          SUM(return_quantity) AS total_return_qty,
          SUM(CASE WHEN return_status = 'Returned' THEN 1 ELSE 0 END) AS num_items_returned,
          COUNT(DISTINCT item_sk) AS distinct_items_sold,
          AVG(avg_price_per_unit) AS avg_price_per_unit_overall
   FROM sales_with_returns
   GROUP BY channel, store_id, web_page_id, call_center_id
),
ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (ORDER BY total_net DESC) AS sales_rank,
          MAX(total_net) OVER () AS max_total_net,
          MIN(total_net) OVER () AS min_total_net
   FROM agg
)
SELECT channel,
       store_id,
       web_page_id,
       call_center_id,
       total_net,
       total_return_qty,
       num_items_returned,
       distinct_items_sold,
       avg_price_per_unit_overall,
       sales_rank,
       max_total_net,
       min_total_net
FROM ranked
WHERE sales_rank <= 10
ORDER BY sales_rank
