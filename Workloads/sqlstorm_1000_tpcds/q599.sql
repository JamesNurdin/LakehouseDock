WITH date_info AS (
    SELECT d_date_sk,
           d_year,
           d_moy,
           CONCAT(CAST(d_year AS VARCHAR), '-', LPAD(CAST(d_moy AS VARCHAR), 2, '0')) AS year_month
    FROM date_dim
), sales_raw AS (
    SELECT 'store' AS sales_channel,
           ss.ss_store_sk AS store_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_ext_discount_amt AS ext_discount_amt,
           ss.ss_coupon_amt AS coupon_amt,
           ss.ss_ext_tax AS ext_tax
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS sales_channel,
           cs.cs_call_center_sk AS store_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_ext_discount_amt AS ext_discount_amt,
           cs.cs_coupon_amt AS coupon_amt,
           cs.cs_ext_tax AS ext_tax
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS sales_channel,
           ws.ws_web_page_sk AS store_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_ext_discount_amt AS ext_discount_amt,
           ws.ws_coupon_amt AS coupon_amt,
           ws.ws_ext_tax AS ext_tax
    FROM web_sales ws
), returns_raw AS (
    SELECT 'store' AS sales_channel,
           sr.sr_store_sk AS store_sk,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_return_amt AS return_amt,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_tax AS return_tax
    FROM store_returns sr
    UNION ALL
    SELECT 'catalog' AS sales_channel,
           cr.cr_call_center_sk AS store_sk,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS return_amt,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_tax AS return_tax
    FROM catalog_returns cr
    UNION ALL
    SELECT 'web' AS sales_channel,
           wr.wr_web_page_sk AS store_sk,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_return_amt AS return_amt,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_tax AS return_tax
    FROM web_returns wr
), sales_agg AS (
    SELECT sr.sales_channel,
           sr.store_sk,
           di.year_month,
           SUM(sr.quantity) AS total_quantity,
           SUM(sr.net_paid) AS total_net_paid,
           SUM(sr.net_profit) AS total_net_profit,
           SUM(sr.ext_sales_price) AS total_ext_sales_price,
           SUM(sr.ext_discount_amt) AS total_discount,
           SUM(sr.coupon_amt) AS total_coupon,
           SUM(sr.ext_tax) AS total_tax
    FROM sales_raw sr
    LEFT JOIN date_info di ON sr.date_sk = di.d_date_sk
    GROUP BY sr.sales_channel, sr.store_sk, di.year_month
), returns_agg AS (
    SELECT rr.sales_channel,
           rr.store_sk,
           di.year_month,
           SUM(rr.quantity) AS total_return_quantity,
           SUM(rr.return_amt) AS total_return_amount,
           SUM(rr.net_loss) AS total_net_loss,
           SUM(rr.return_tax) AS total_return_tax
    FROM returns_raw rr
    LEFT JOIN date_info di ON rr.date_sk = di.d_date_sk
    GROUP BY rr.sales_channel, rr.store_sk, di.year_month
), combined AS (
    SELECT s.sales_channel,
           s.store_sk,
           s.year_month,
           s.total_quantity,
           s.total_net_paid,
           s.total_net_profit,
           COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
           COALESCE(r.total_return_amount, 0) AS total_return_amount,
           COALESCE(r.total_net_loss, 0) AS total_net_loss,
           COALESCE(r.total_return_tax, 0) AS total_return_tax,
           (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS adj_net_profit,
           (s.total_net_paid - COALESCE(r.total_return_amount, 0) + COALESCE(r.total_return_tax, 0)) AS adj_net_paid
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.sales_channel = r.sales_channel
        AND s.store_sk = r.store_sk
        AND s.year_month = r.year_month
), ranked AS (
    SELECT c.sales_channel,
           c.store_sk,
           c.year_month,
           c.total_quantity,
           c.total_net_paid,
           c.total_net_profit,
           c.total_return_quantity,
           c.total_return_amount,
           c.total_net_loss,
           c.adj_net_profit,
           c.adj_net_paid,
           ROW_NUMBER() OVER (PARTITION BY c.sales_channel, c.year_month ORDER BY c.adj_net_profit DESC) AS profit_rank,
           SUM(c.adj_net_profit) OVER (PARTITION BY c.sales_channel ORDER BY c.year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_adj_net_profit,
           AVG(c.adj_net_profit) OVER (PARTITION BY c.sales_channel, c.year_month) AS avg_adj_net_profit_per_channel_month
    FROM combined c
), store_info AS (
    SELECT s.s_store_sk AS store_sk,
           CONCAT(s.s_store_name, ' (', s.s_city, ')') AS store_label,
           s.s_state,
           s.s_gmt_offset,
           s.s_tax_percentage,
           s.s_number_employees,
           s.s_floor_space
    FROM store s
), final AS (
    SELECT r.sales_channel,
           r.year_month,
           COALESCE(i.store_label, CAST(r.store_sk AS VARCHAR)) AS store,
           i.s_state,
           i.s_number_employees,
           r.total_quantity,
           r.total_net_paid,
           r.total_net_profit,
           r.total_return_quantity,
           r.total_return_amount,
           r.total_net_loss,
           r.adj_net_profit,
           r.adj_net_paid,
           r.profit_rank,
           r.cumulative_adj_net_profit,
           r.avg_adj_net_profit_per_channel_month,
           CASE
               WHEN i.s_number_employees IS NOT NULL AND i.s_number_employees > 0 THEN r.adj_net_profit / i.s_number_employees
               ELSE NULL
           END AS profit_per_employee,
           CASE
               WHEN r.total_quantity = 0 THEN NULL
               ELSE r.total_net_profit / r.total_quantity
           END AS profit_per_item,
           CASE
               WHEN r.adj_net_profit > 0 THEN 'POSITIVE'
               WHEN r.adj_net_profit < 0 THEN 'NEGATIVE'
               ELSE 'ZERO'
           END AS profit_sign,
           CONCAT(LOWER(r.sales_channel), '_', REPLACE(r.year_month, '-', ''), '_', CAST(r.store_sk AS VARCHAR)) AS composite_key
    FROM ranked r
    LEFT JOIN store_info i ON r.store_sk = i.store_sk
    WHERE (r.adj_net_profit > 0 OR r.total_return_quantity IS NOT NULL)
), max_cumulative AS (
    SELECT t.sales_channel,
           t.year_month,
           t.store,
           t.cumulative_adj_net_profit,
           (SELECT MAX(c.cumulative_adj_net_profit) FROM ranked c WHERE c.sales_channel = t.sales_channel) AS channel_max_cum_profit
    FROM final t
)
SELECT m.sales_channel,
       m.year_month,
       m.store,
       m.cumulative_adj_net_profit,
       m.channel_max_cum_profit,
       (m.cumulative_adj_net_profit / NULLIF(m.channel_max_cum_profit, 0)) * 100 AS cum_profit_pct_of_channel,
       CASE
           WHEN m.cumulative_adj_net_profit = m.channel_max_cum_profit THEN 'TOP'
           ELSE 'OTHER'
       END AS ranking_flag
FROM max_cumulative m
ORDER BY m.sales_channel, m.cumulative_adj_net_profit DESC
LIMIT 100
