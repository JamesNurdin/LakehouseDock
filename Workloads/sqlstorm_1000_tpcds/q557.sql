WITH sales_union AS (
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, cs.cs_ext_sales_price AS sales_amount, cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, ss.ss_ext_sales_price, ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, ws.ws_ext_sales_price, ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
), sales_agg AS (
    SELECT d_year, d_month_seq, i_category, i_brand,
           sum(sales_amount) AS total_sales_amount,
           sum(net_profit) AS total_net_profit
    FROM sales_union
    GROUP BY d_year, d_month_seq, i_category, i_brand
), returns_union AS (
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, d.d_month_seq, i.i_category, i.i_brand, wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
), returns_agg AS (
    SELECT d_year, d_month_seq, i_category, i_brand,
           sum(net_loss) AS total_net_loss
    FROM returns_union
    GROUP BY d_year, d_month_seq, i_category, i_brand
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_brand,
    s.total_sales_amount,
    s.total_net_profit,
    coalesce(r.total_net_loss, 0) AS total_net_loss,
    (s.total_net_profit - coalesce(r.total_net_loss, 0)) AS net_contribution,
    CASE WHEN s.total_sales_amount > 0 THEN (s.total_net_profit - coalesce(r.total_net_loss, 0)) / s.total_sales_amount ELSE 0 END AS profit_margin,
    lag(s.total_net_profit) OVER (PARTITION BY s.i_category, s.i_brand ORDER BY s.d_year, s.d_month_seq) AS prev_month_net_profit,
    (s.total_net_profit - lag(s.total_net_profit) OVER (PARTITION BY s.i_category, s.i_brand ORDER BY s.d_year, s.d_month_seq)) AS month_profit_change,
    row_number() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_net_profit DESC) AS profit_rank_in_month
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.i_category = r.i_category
 AND s.i_brand = r.i_brand
WHERE s.d_year BETWEEN 1999 AND 2002
ORDER BY s.d_year, s.d_month_seq, net_contribution DESC
LIMIT 100
