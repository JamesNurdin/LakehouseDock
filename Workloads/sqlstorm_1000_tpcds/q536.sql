WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS revenue,
           cs.cs_net_profit AS profit,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_call_center_sk AS call_center_sk,
           NULL AS store_sk,
           NULL AS web_site_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           ss.ss_promo_sk,
           NULL,
           ss.ss_store_sk,
           NULL,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_promo_sk,
           NULL,
           NULL,
           ws.ws_web_site_sk,
           'web'
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           -(cr.cr_refunded_cash + cr.cr_store_credit + cr.cr_reversed_charge + cr.cr_fee + cr.cr_return_ship_cost) AS loss,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           -(sr.sr_refunded_cash + sr.sr_store_credit + sr.sr_reversed_charge + sr.sr_fee + sr.sr_return_ship_cost) AS loss,
           'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           -(wr.wr_refunded_cash + wr.wr_account_credit + wr.wr_reversed_charge + wr.wr_fee + wr.wr_return_ship_cost) AS loss,
           'web' AS channel
    FROM web_returns wr
),
promo_cost AS (
    SELECT p.p_promo_sk,
           p.p_cost
    FROM promotion p
),
aggregated AS (
    SELECT
        dd.d_year AS d_year,
        dd.d_month_seq AS month_seq,
        s.channel,
        i.i_category,
        i.i_brand,
        SUM(s.revenue) AS total_revenue,
        SUM(s.profit) AS total_profit,
        COALESCE(SUM(r.loss), 0) AS total_loss,
        SUM(COALESCE(pc.p_cost, 0)) AS total_promo_cost,
        SUM(s.revenue) - COALESCE(SUM(r.loss), 0) - SUM(COALESCE(pc.p_cost, 0)) AS net_income,
        SUM(s.quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY dd.d_year, dd.d_month_seq, s.channel ORDER BY SUM(s.profit) DESC) AS profit_rank
    FROM sales s
    LEFT JOIN returns r
        ON s.date_sk = r.date_sk
       AND s.item_sk = r.item_sk
       AND s.channel = r.channel
    LEFT JOIN date_dim dd
        ON s.date_sk = dd.d_date_sk
    LEFT JOIN item i
        ON s.item_sk = i.i_item_sk
    LEFT JOIN promo_cost pc
        ON s.promo_sk = pc.p_promo_sk
    LEFT JOIN call_center cc
        ON s.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store st
        ON s.store_sk = st.s_store_sk
    LEFT JOIN web_site wsit
        ON s.web_site_sk = wsit.web_site_sk
    GROUP BY
        dd.d_year,
        dd.d_month_seq,
        s.channel,
        i.i_category,
        i.i_brand
),
top_items AS (
    SELECT *
    FROM aggregated
    WHERE profit_rank <= 5
)
SELECT
    d_year,
    month_seq,
    channel,
    i_category,
    i_brand,
    total_revenue,
    total_profit,
    total_loss,
    total_promo_cost,
    net_income,
    total_quantity,
    profit_rank
FROM top_items
ORDER BY d_year, month_seq, channel, profit_rank
