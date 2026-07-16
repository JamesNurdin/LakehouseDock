WITH sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           s.channel,
           COALESCE(cc.cc_name, st.s_store_name, 'N/A') AS entity_name,
           p.p_promo_name,
           SUM(s.quantity) AS total_quantity_sold,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit
    FROM (
        SELECT cs.cs_sold_date_sk AS date_sk,
               cs.cs_item_sk AS item_sk,
               cs.cs_quantity AS quantity,
               cs.cs_net_paid AS net_paid,
               cs.cs_net_profit AS net_profit,
               cs.cs_call_center_sk AS call_center_sk,
               NULL AS store_sk,
               cs.cs_promo_sk AS promo_sk,
               'catalog' AS channel
        FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_sold_date_sk,
               ss.ss_item_sk,
               ss.ss_quantity,
               ss.ss_net_paid,
               ss.ss_net_profit,
               NULL,
               ss.ss_store_sk,
               ss.ss_promo_sk,
               'store'
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_sold_date_sk,
               ws.ws_item_sk,
               ws.ws_quantity,
               ws.ws_net_paid,
               ws.ws_net_profit,
               NULL,
               NULL,
               ws.ws_promo_sk,
               'web'
        FROM web_sales ws
    ) s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store st ON s.channel = 'store' AND s.store_sk = st.s_store_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year,
             d.d_month_seq,
             i.i_category,
             i.i_class,
             i.i_brand,
             s.channel,
             COALESCE(cc.cc_name, st.s_store_name, 'N/A'),
             p.p_promo_name
),
returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_class,
           i.i_brand,
           r.channel,
           SUM(r.quantity) AS total_return_quantity,
           SUM(r.return_amount) AS total_return_amount,
           SUM(r.net_loss) AS total_return_loss
    FROM (
        SELECT cr.cr_returned_date_sk AS date_sk,
               cr.cr_item_sk AS item_sk,
               cr.cr_return_quantity AS quantity,
               cr.cr_return_amount AS return_amount,
               cr.cr_net_loss AS net_loss,
               'catalog' AS channel
        FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_returned_date_sk,
               sr.sr_item_sk,
               sr.sr_return_quantity,
               sr.sr_return_amt,
               sr.sr_net_loss,
               'store'
        FROM store_returns sr
        UNION ALL
        SELECT wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_quantity,
               wr.wr_return_amt,
               wr.wr_net_loss,
               'web'
        FROM web_returns wr
    ) r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY d.d_year,
             d.d_month_seq,
             i.i_category,
             i.i_class,
             i.i_brand,
             r.channel
)
SELECT s.d_year,
       s.d_month_seq,
       s.i_category,
       s.i_class,
       s.i_brand,
       s.channel,
       s.entity_name,
       s.p_promo_name,
       s.total_quantity_sold,
       s.total_net_paid,
       s.total_net_profit,
       COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
       RANK() OVER (PARTITION BY s.d_year, s.d_month_seq, s.channel ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.i_category = r.i_category
 AND s.i_class = r.i_class
 AND s.i_brand = r.i_brand
 AND s.channel = r.channel
WHERE s.total_net_profit > 0
ORDER BY s.d_year,
         s.d_month_seq,
         s.channel,
         profit_rank
LIMIT 50
