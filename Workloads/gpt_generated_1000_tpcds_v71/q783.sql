WITH ss_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            ss.ss_promo_sk,
            ss.ss_customer_sk,
            ss.ss_hdemo_sk,
            SUM(ss.ss_net_profit)   AS store_net_profit,
            SUM(ss.ss_quantity)     AS store_qty
        FROM store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk, ss.ss_customer_sk, ss.ss_hdemo_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_returned_date_sk,
            sr.sr_reason_sk,
            sr.sr_hdemo_sk,
            SUM(sr.sr_return_quantity) AS total_return_qty,
            SUM(sr.sr_net_loss)        AS total_return_loss
        FROM store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk, sr.sr_reason_sk, sr.sr_hdemo_sk
    ),
    ws_agg AS (
        SELECT
            ws.ws_web_site_sk,
            ws.ws_sold_date_sk,
            ws.ws_promo_sk,
            ws.ws_bill_hdemo_sk,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(ws.ws_quantity)   AS web_qty
        FROM web_sales ws
        GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, ws.ws_promo_sk, ws.ws_bill_hdemo_sk
    ),
    wr_agg AS (
        SELECT
            wr.wr_web_page_sk,
            wr.wr_returned_date_sk,
            wr.wr_reason_sk,
            wr.wr_refunded_hdemo_sk,
            SUM(wr.wr_return_quantity) AS total_web_return_qty,
            SUM(wr.wr_net_loss)        AS total_web_return_loss
        FROM web_returns wr
        GROUP BY wr.wr_web_page_sk, wr.wr_returned_date_sk, wr.wr_reason_sk, wr.wr_refunded_hdemo_sk
    )
SELECT
    s.s_store_name,
    d_ss.d_year,
    d_ss.d_month_seq,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    p.p_promo_name,
    r_sr.r_reason_desc          AS store_return_reason,
    r_wr.r_reason_desc          AS web_return_reason,
    cc.cc_name,
    ws_site.web_name,
    wp.wp_url,
    ss_agg.store_net_profit,
    ss_agg.store_qty,
    sr_agg.total_return_qty,
    sr_agg.total_return_loss,
    ws_agg.web_net_profit,
    ws_agg.web_qty,
    wr_agg.total_web_return_qty,
    wr_agg.total_web_return_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.store_net_profit DESC) AS store_profit_rank,
    RANK()      OVER (ORDER BY (ss_agg.store_net_profit + ws_agg.web_net_profit) DESC) AS overall_profit_rank
FROM ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
  ON ss_agg.ss_sold_date_sk = d_ss.d_date_sk
JOIN promotion p
  ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN customer c
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN sr_agg
  ON sr_agg.sr_store_sk = s.s_store_sk
 AND sr_agg.sr_returned_date_sk = d_ss.d_date_sk
JOIN reason r_sr
  ON sr_agg.sr_reason_sk = r_sr.r_reason_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_ss.d_date_sk
JOIN web_site ws_site
  ON ws_site.web_open_date_sk = d_ss.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_ss.d_date_sk
JOIN ws_agg
  ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
 AND ws_agg.ws_sold_date_sk = d_ss.d_date_sk
 AND ws_agg.ws_promo_sk = p.p_promo_sk
JOIN wr_agg
  ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
 AND wr_agg.wr_returned_date_sk = d_ss.d_date_sk
JOIN reason r_wr
  ON wr_agg.wr_reason_sk = r_wr.r_reason_sk
WHERE d_ss.d_year = 2001
  AND c.c_birth_year BETWEEN 1950 AND 1990
  AND hd.hd_income_band_sk IN (1, 2, 3, 4)
  AND p.p_discount_active = 'Y'
  AND cc.cc_country = 'United States'
  AND ws_site.web_state = 'CA'
ORDER BY overall_profit_rank, d_ss.d_year
LIMIT 100
