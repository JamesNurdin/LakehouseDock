WITH sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_call_center_sk AS sale_location_sk,
          cs.cs_quantity AS quantity,
          cs.cs_net_paid AS net_paid,
          cs.cs_ext_discount_amt AS discount,
          'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_store_sk,
          ss.ss_quantity,
          ss.ss_net_paid,
          ss.ss_ext_discount_amt,
          'store'
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_warehouse_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_ext_discount_amt,
          'web'
   FROM web_sales ws
),
returns AS (
   SELECT cr.cr_returned_date_sk AS date_sk,
          cr.cr_item_sk AS item_sk,
          cr.cr_return_quantity AS quantity,
          cr.cr_return_amount AS return_amount,
          'catalog' AS channel
   FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_returned_date_sk,
          sr.sr_item_sk,
          sr.sr_return_quantity,
          sr.sr_return_amt,
          'store'
   FROM store_returns sr
   UNION ALL
   SELECT wr.wr_returned_date_sk,
          wr.wr_item_sk,
          wr.wr_return_quantity,
          wr.wr_return_amt,
          'web'
   FROM web_returns wr
),
joined AS (
   SELECT s.date_sk,
          s.item_sk,
          s.sale_location_sk,
          s.quantity,
          s.net_paid,
          s.discount,
          s.channel,
          i.i_category,
          i.i_class,
          i.i_brand,
          d.d_year,
          d.d_quarter_seq,
          COALESCE(r.return_amount, 0) AS return_amount,
          COALESCE(r.quantity, 0) AS return_quantity
   FROM sales s
   LEFT JOIN item i ON s.item_sk = i.i_item_sk
   LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
   LEFT JOIN returns r ON s.date_sk = r.date_sk AND s.item_sk = r.item_sk AND s.channel = r.channel
),
agg AS (
   SELECT d_year,
          d_quarter_seq,
          i_category,
          i_brand,
          channel,
          SUM(net_paid) AS total_net_paid,
          SUM(return_amount) AS total_returns,
          SUM(quantity) AS total_quantity,
          SUM(return_quantity) AS total_return_quantity,
          SUM(discount) AS total_discount,
          COUNT(DISTINCT item_sk) AS distinct_items_sold,
          AVG(net_paid / NULLIF(quantity, 0)) AS avg_price,
          RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY SUM(net_paid) DESC) AS sales_rank
   FROM joined
   GROUP BY d_year,
            d_quarter_seq,
            i_category,
            i_brand,
            channel
)
SELECT d_year,
       d_quarter_seq,
       i_category,
       i_brand,
       channel,
       total_net_paid,
       total_returns,
       total_quantity,
       total_return_quantity,
       total_discount,
       distinct_items_sold,
       avg_price,
       sales_rank
FROM agg
WHERE sales_rank <= 5
ORDER BY d_year, d_quarter_seq, sales_rank
