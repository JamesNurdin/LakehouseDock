WITH sales_raw AS (
 SELECT cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel
 FROM catalog_sales cs
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_net_paid,
        NULL,
        ss.ss_store_sk,
        NULL,
        ss.ss_promo_sk,
        'store'
 FROM store_sales ss
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        NULL,
        NULL,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        'web'
 FROM web_sales ws
),
sales_with_promo AS (
 SELECT s.*,
        COALESCE(p.p_cost, 0) AS promo_cost
 FROM sales_raw s
 LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
),
sales_agg AS (
 SELECT date_sk,
        channel,
        item_sk,
        SUM(net_profit) AS sum_net_profit,
        SUM(net_paid) AS sum_net_paid,
        SUM(quantity) AS sum_quantity,
        SUM(promo_cost) AS sum_promo_cost
 FROM sales_with_promo
 GROUP BY date_sk, channel, item_sk
),
returns_raw AS (
 SELECT cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss,
        cr.cr_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        'catalog' AS channel
 FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        NULL,
        sr.sr_store_sk,
        NULL,
        'store'
 FROM store_returns sr
 UNION ALL
 SELECT wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        NULL,
        NULL,
        wr.wr_web_page_sk,
        'web'
 FROM web_returns wr
),
returns_agg AS (
 SELECT date_sk,
        channel,
        item_sk,
        SUM(net_loss) AS sum_net_loss,
        SUM(quantity) AS sum_return_quantity
 FROM returns_raw
 GROUP BY date_sk, channel, item_sk
),
base_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category,
        s.channel,
        SUM(s.sum_net_profit) AS total_net_profit,
        SUM(s.sum_net_paid) AS total_net_paid,
        SUM(s.sum_quantity) AS total_quantity_sold,
        COALESCE(SUM(r.sum_net_loss), 0) AS total_return_loss,
        COALESCE(SUM(r.sum_return_quantity), 0) AS total_quantity_returned,
        SUM(s.sum_promo_cost) AS total_promo_cost
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON s.item_sk = r.item_sk
  AND s.date_sk = r.date_sk
  AND s.channel = r.channel
 JOIN date_dim d ON s.date_sk = d.d_date_sk
 JOIN item i ON s.item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1998 AND 2002
 GROUP BY d.d_year, d.d_month_seq, i.i_category, s.channel
 HAVING SUM(s.sum_net_profit) > 0
)
SELECT d_year,
       d_month_seq,
       i_category,
       channel,
       total_net_profit,
       total_net_paid,
       total_quantity_sold,
       total_return_loss,
       total_quantity_returned,
       total_promo_cost,
       CASE WHEN total_net_profit > 0 THEN total_return_loss / total_net_profit ELSE NULL END AS return_loss_ratio,
       CASE WHEN total_quantity_sold > 0 THEN total_quantity_returned * 100.0 / total_quantity_sold ELSE NULL END AS return_quantity_percent,
       ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_net_profit DESC) AS profit_rank
FROM base_agg
ORDER BY d_year, channel, profit_rank
LIMIT 200
