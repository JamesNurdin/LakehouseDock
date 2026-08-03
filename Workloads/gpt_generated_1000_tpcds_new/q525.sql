WITH recent_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
)
SELECT *
FROM (
    SELECT
        s.s_store_id AS entity_id,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        COALESCE(sr_agg.return_amount, 0) AS return_amount
    FROM store_sales ss
    JOIN recent_dates d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT SUM(sr.sr_return_amt) AS return_amount
        FROM store_returns sr
        WHERE sr.sr_store_sk = s.s_store_sk
          AND sr.sr_returned_date_sk = d.d_date_sk
    ) AS sr_agg ON TRUE
    GROUP BY s.s_store_id, d.d_month_seq, sr_agg.return_amount
) 
INTERSECT
SELECT *
FROM (
    SELECT
        w.web_site_id AS entity_id,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        COALESCE(wr_agg.return_amount, 0) AS return_amount
    FROM web_sales ws
    JOIN recent_dates d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN LATERAL (
        SELECT SUM(wr.wr_return_amt) AS return_amount
        FROM web_returns wr
        WHERE wr.wr_web_page_sk = ws.ws_web_page_sk
          AND wr.wr_returned_date_sk = d.d_date_sk
    ) AS wr_agg ON TRUE
    GROUP BY w.web_site_id, d.d_month_seq, wr_agg.return_amount
) 
LIMIT 100
