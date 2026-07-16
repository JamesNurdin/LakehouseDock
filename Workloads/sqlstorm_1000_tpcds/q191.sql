WITH sales_by_channel AS (
    SELECT
        d.d_date_sk AS date_sk,
        d.d_date AS sale_date,
        'store' AS channel,
        ss.ss_store_sk AS entity_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, ss.ss_store_sk

    UNION ALL

    SELECT
        d.d_date_sk AS date_sk,
        d.d_date AS sale_date,
        'web' AS channel,
        ws.ws_web_page_sk AS entity_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, ws.ws_web_page_sk

    UNION ALL

    SELECT
        d.d_date_sk AS date_sk,
        d.d_date AS sale_date,
        'catalog' AS channel,
        cs.cs_call_center_sk AS entity_id,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date, cs.cs_call_center_sk
)

SELECT
    s.sale_date,
    s.channel,
    s.entity_id,
    COALESCE(st.s_store_name, cc.cc_name, wp.wp_url) AS entity_name,
    s.total_net_paid,
    s.total_net_profit,
    s.total_discount,
    s.txn_count,
    CASE
        WHEN s.total_net_paid = 0 THEN 0
        ELSE s.total_net_profit / NULLIF(s.total_net_paid, 0)
    END AS profit_margin,
    CASE
        WHEN CASE
                 WHEN s.total_net_paid = 0 THEN 0
                 ELSE s.total_net_profit / NULLIF(s.total_net_paid, 0)
             END >= 0.2 THEN 'HIGH'
        WHEN CASE
                 WHEN s.total_net_paid = 0 THEN 0
                 ELSE s.total_net_profit / NULLIF(s.total_net_paid, 0)
             END >= 0.1 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY s.channel ORDER BY s.total_net_profit DESC) AS profit_rank_desc,
    (SELECT COALESCE(SUM(sr.sr_return_amt), 0)
     FROM store_returns sr
     WHERE sr.sr_returned_date_sk = s.date_sk
       AND sr.sr_store_sk = s.entity_id) AS store_return_amount,
    (SELECT COALESCE(SUM(wr.wr_return_amt), 0)
     FROM web_returns wr
     WHERE wr.wr_returned_date_sk = s.date_sk
       AND wr.wr_web_page_sk = s.entity_id) AS web_return_amount,
    (SELECT COALESCE(SUM(cr.cr_return_amount), 0)
     FROM catalog_returns cr
     WHERE cr.cr_returned_date_sk = s.date_sk
       AND cr.cr_call_center_sk = s.entity_id) AS catalog_return_amount,
    UPPER(s.channel) AS channel_upper,
    CONCAT(s.channel, '_', CAST(s.date_sk AS VARCHAR)) AS channel_date_key,
    dd.d_day_name,
    CONCAT('Profit on ', CAST(s.sale_date AS VARCHAR), ': ', CAST(s.total_net_profit AS VARCHAR)) AS profit_summary
FROM sales_by_channel s
LEFT JOIN store st
    ON s.channel = 'store' AND s.entity_id = st.s_store_sk
LEFT JOIN call_center cc
    ON s.channel = 'catalog' AND s.entity_id = cc.cc_call_center_sk
LEFT JOIN web_page wp
    ON s.channel = 'web' AND s.entity_id = wp.wp_web_page_sk
LEFT JOIN date_dim dd
    ON s.date_sk = dd.d_date_sk
WHERE s.sale_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND (s.total_discount > 0 OR s.total_net_paid > 1000)
  AND s.total_net_profit > (
        SELECT AVG(s2.total_net_profit)
        FROM sales_by_channel s2
        WHERE s2.channel = s.channel
      )
ORDER BY s.sale_date, s.channel
