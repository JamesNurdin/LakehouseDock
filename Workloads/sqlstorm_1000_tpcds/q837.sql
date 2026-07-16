WITH unified_sales AS (
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS txn_id,
        ss.ss_quantity AS quantity,
        'store' AS channel
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 UNION ALL
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_quantity,
        'web' AS channel
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 UNION ALL
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_quantity,
        'catalog' AS channel
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
sales_agg AS (
 SELECT i_category,
        d_year,
        d_quarter_seq,
        channel,
        SUM(net_paid_inc_tax) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(DISTINCT txn_id) AS total_transactions,
        SUM(quantity) AS total_quantity
 FROM unified_sales
 WHERE d_year BETWEEN 1999 AND 2002
 GROUP BY i_category, d_year, d_quarter_seq, channel
),
unified_returns AS (
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity,
        'store' AS channel
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 UNION ALL
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        'catalog' AS channel
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 UNION ALL
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        'web' AS channel
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns_agg AS (
 SELECT i_category,
        d_year,
        d_quarter_seq,
        channel,
        SUM(net_loss) AS total_loss,
        SUM(return_quantity) AS total_return_qty
 FROM unified_returns
 WHERE d_year BETWEEN 1999 AND 2002
 GROUP BY i_category, d_year, d_quarter_seq, channel
),
promo_agg AS (
 SELECT i.i_category,
        d.d_year,
        d.d_quarter_seq,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
 FROM promotion p
 JOIN date_dim d ON p.p_start_date_sk <= d.d_date_sk AND p.p_end_date_sk >= d.d_date_sk
 JOIN item i ON p.p_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
 GROUP BY i.i_category, d.d_year, d.d_quarter_seq
)
SELECT
    s.i_category,
    s.d_year,
    s.d_quarter_seq,
    s.channel,
    s.total_sales,
    s.total_profit,
    s.total_transactions,
    s.total_quantity,
    r.total_loss,
    r.total_return_qty,
    p.total_promo_cost,
    p.promo_count,
    (s.total_sales - COALESCE(r.total_loss, 0)) / NULLIF(s.total_sales, 0) AS net_sales_ratio,
    CASE WHEN s.total_sales > 0 THEN s.total_profit / s.total_sales ELSE NULL END AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY s.i_category, s.d_year, s.channel ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.i_category = r.i_category
 AND s.d_year = r.d_year
 AND s.d_quarter_seq = r.d_quarter_seq
 AND s.channel = r.channel
LEFT JOIN promo_agg p
  ON s.i_category = p.i_category
 AND s.d_year = p.d_year
 AND s.d_quarter_seq = p.d_quarter_seq
WHERE s.total_sales > 0
ORDER BY s.i_category, s.d_year, s.d_quarter_seq, s.channel, sales_rank
LIMIT 500
